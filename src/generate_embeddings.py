# src/generate_embeddings.py
"""
Main script for generating embeddings from event data
"""

import sys
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Tuple
import numpy as np
from sentence_transformers import SentenceTransformer
from pgvector.psycopg2 import register_vector
import psycopg2
from psycopg2 import sql

from config import config
from utils import (
    get_logger, timer, batch_iterator, ensure_timezone_aware,
    clean_text, format_list_human, safe_json_dumps,
    DatabaseConnection, ProgressTracker, validate_embeddings,
    format_duration
)


logger = get_logger(__name__)


class EmbeddingsGenerator:
    """
    Main class for generating and storing embeddings
    """
    
    def __init__(self):
        self.config = config
        self.model: Optional[SentenceTransformer] = None
        self.source_db: Optional[DatabaseConnection] = None
        self.dest_db: Optional[DatabaseConnection] = None
        self.current_incremental_mode = False
        
    def initialize(self) -> bool:
        """
        Initialize connections and model
        """
        try:
            # Validate configuration
            if not self.config.validate():
                logger.error("Invalid configuration")
                return False
            
            logger.info(f"Configuration: {self.config}")
            
            # Connect to databases
            self.source_db = DatabaseConnection(self.config.source_db.to_dict())
            self.dest_db = DatabaseConnection(self.config.dest_db.to_dict())
            
            with self.dest_db:
                register_vector(self.dest_db.connection)
            
            # Load model
            with timer("Loading embedding model", logger):
                self.model = SentenceTransformer(
                    self.config.embedding.model_name,
                    device=self.config.embedding.device
                )
            
            # Verify destination tables
            self._verify_destination_tables()
            
            # Determine execution mode
            self._determine_execution_mode()
            
            return True
            
        except Exception as e:
            logger.error(f"Initialization failed: {e}")
            return False
    
    def _verify_destination_tables(self):
        """
        Verify that required tables exist in destination database.
        Does NOT create tables - assumes they were created by SQL scripts.
        """
        logger.info("Verificando tablas en base de datos destino...")
        
        required_tables = [
            self.config.table_names['sessions'],
            self.config.table_names['speakers'],
            self.config.table_names['sync_log']
        ]
        
        missing_tables = []
        
        with self.dest_db:
            # Verificar extensión vector
            result = self.dest_db.execute_query("""
                SELECT EXISTS (
                    SELECT FROM pg_extension WHERE extname = 'vector'
                );
            """)
            
            if not result[0][0]:
                raise RuntimeError(
                    "ERROR: La extensión 'vector' no está instalada en la base de datos destino.\n"
                    "Por favor, ejecute: CREATE EXTENSION vector;"
                )
            
            # Verificar cada tabla requerida
            for table in required_tables:
                result = self.dest_db.execute_query("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = 'public' 
                        AND table_name = %s
                    );
                """, (table,))
                
                if not result[0][0]:
                    missing_tables.append(table)
                else:
                    # Verificar que la tabla tiene las columnas esperadas
                    if table == self.config.table_names['sessions']:
                        self._verify_table_structure(table, [
                            'session_id', 'event_id', 'content', 'embedding',
                            'session_name', 'session_date', 'start_time', 'end_time'
                        ])
                    elif table == self.config.table_names['speakers']:
                        self._verify_table_structure(table, [
                            'speaker_id', 'speaker_name', 'content', 'embedding'
                        ])
            
            if missing_tables:
                raise RuntimeError(
                    f"ERROR: Las siguientes tablas no existen en la base de datos destino:\n"
                    f"  {', '.join(missing_tables)}\n\n"
                    f"Por favor, ejecute el script SQL de inicialización:\n"
                    f"  psql -h {self.config.dest_db.host} -U {self.config.dest_db.user} "
                    f"-d {self.config.dest_db.dbname} -f sql/03-schema-vector.sql"
                )
            
            logger.info("✓ Todas las tablas requeridas existen")
            logger.info("✓ Extensión vector instalada")
    
    def _verify_table_structure(self, table_name: str, required_columns: List[str]):
        """
        Verify that a table has the required columns
        """
        with self.dest_db:
            result = self.dest_db.execute_query("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = %s;
            """, (table_name,))
            
            existing_columns = {row[0] for row in result}
            missing_columns = set(required_columns) - existing_columns
            
            if missing_columns:
                logger.warning(
                    f"Tabla '{table_name}' tiene columnas faltantes: {missing_columns}. "
                    f"Esto podría causar errores."
                )
    
    def _determine_execution_mode(self):
        """
        Determine if we should run in incremental mode
        """
        if self.config.processing.incremental_mode == "true":
            self.current_incremental_mode = True
        elif self.config.processing.incremental_mode == "false":
            self.current_incremental_mode = False
        else:  # auto
            # Check if we have previous successful syncs
            with self.dest_db:
                result = self.dest_db.execute_query(f"""
                    SELECT COUNT(*) FROM {self.config.table_names['sync_log']}
                    WHERE status = 'SUCCESS' AND table_name = %s
                """, (self.config.table_names['sessions'],))
                
                sync_count = result[0][0] if result else 0
                self.current_incremental_mode = sync_count > 0
        
        logger.info(f"Execution mode: {'INCREMENTAL' if self.current_incremental_mode else 'FULL'}")
    
    def _get_last_sync_time(self) -> datetime:
        """
        Get the timestamp of the last successful sync
        """
        with self.dest_db:
            result = self.dest_db.execute_query(f"""
                SELECT MAX(sync_timestamp)
                FROM {self.config.table_names['sync_log']}
                WHERE status = 'SUCCESS' AND table_name = %s
            """, (self.config.table_names['sessions'],))
            
            if result and result[0][0]:
                return ensure_timezone_aware(result[0][0])
            else:
                # Return a very old date for first run
                return datetime(2000, 1, 1, tzinfo=timezone.utc)
    
    def fetch_sessions(self) -> List[Dict]:
        """
        Fetch all sessions that need processing
        """
        logger.info("Fetching sessions from source database...")
        
        # Build WHERE clause for incremental mode
        where_clause = ""
        params = []
        
        if self.current_incremental_mode:
            last_sync = self._get_last_sync_time()
            lookback = datetime.now(timezone.utc) - timedelta(hours=self.config.processing.lookback_hours)
            since_timestamp = max(last_sync, lookback)
            
            logger.info(f"Fetching sessions modified since: {since_timestamp}")
            
            # For now, fetch all sessions (you can add updated_at logic here)
            # This is a simplified version
        
        query = """
            SELECT 
                s.id,
                s.session_name,
                s.start_time,
                s.end_time,
                COALESCE(r.room_name, v.venue_name, 'Sin ubicación') as location,
                s.event_id,
                sp.id as speaker_id,
                sp.name as speaker_name,
                sp.bio as speaker_bio,
                array_agg(DISTINCT t.tag_name) FILTER (WHERE t.tag_name IS NOT NULL) as tags,
                s.session_date
            FROM schedules s
            LEFT JOIN events e ON s.event_id = e.id
            LEFT JOIN rooms r ON s.room_id = r.id
            LEFT JOIN venues v ON r.venue_id = v.id
            LEFT JOIN speakers sp ON s.speaker_id = sp.id
            LEFT JOIN session_tags st ON s.id = st.session_id
            LEFT JOIN tags t ON st.tag_id = t.id
            GROUP BY s.id, s.session_name, s.start_time, s.end_time, 
                     s.event_id, sp.id, sp.name, sp.bio, s.session_date,
                     r.room_name, v.venue_name
            ORDER BY s.start_time
        """
        
        with self.source_db:
            results = self.source_db.execute_query(query)
            
            sessions = []
            for row in results:
                sessions.append({
                    'id': row[0],
                    'name': row[1],
                    'start_time': row[2],
                    'end_time': row[3],
                    'location': row[4],
                    'event_id': row[5],
                    'speaker_id': row[6],
                    'speaker_name': row[7],
                    'speaker_bio': row[8],
                    'tags': row[9] or [],
                    'date': row[10]
                })
            
            logger.info(f"Fetched {len(sessions)} sessions")
            return sessions
    
    def fetch_speakers(self) -> List[Dict]:
        """
        Fetch all speakers with their session information
        """
        logger.info("Fetching speakers from source database...")
        
        query = """
            SELECT 
                sp.id,
                sp.name,
                sp.bio,
                COUNT(DISTINCT s.id) as session_count,
                array_agg(DISTINCT s.session_name) FILTER (WHERE s.session_name IS NOT NULL) as session_names,
                array_agg(DISTINCT t.tag_name) FILTER (WHERE t.tag_name IS NOT NULL) as all_tags
            FROM speakers sp
            LEFT JOIN schedules s ON sp.id = s.speaker_id
            LEFT JOIN session_tags st ON s.id = st.session_id
            LEFT JOIN tags t ON st.tag_id = t.id
            GROUP BY sp.id, sp.name, sp.bio
        """
        
        with self.source_db:
            results = self.source_db.execute_query(query)
            
            speakers = []
            for row in results:
                speakers.append({
                    'id': row[0],
                    'name': row[1],
                    'bio': row[2],
                    'session_count': row[3],
                    'session_names': row[4] or [],
                    'all_tags': row[5] or []
                })
            
            logger.info(f"Fetched {len(speakers)} speakers")
            return speakers
    
    def generate_session_content(self, session: Dict) -> str:
        """
        Generate text content for session embedding
        """
        parts = []
        
        # Basic information
        parts.append(f"Sesión: {session['name']}")
        
        # Date and time
        if session.get('date'):
            parts.append(f"Fecha: {session['date'].strftime('%d/%m/%Y')}")
        parts.append(f"Horario: {session['start_time'].strftime('%H:%M')} - {session['end_time'].strftime('%H:%M')}")
        
        # Duration
        duration_td = datetime.combine(datetime.min, session['end_time']) - datetime.combine(datetime.min, session['start_time'])
        duration_minutes = int(duration_td.total_seconds() / 60)
        parts.append(f"Duración: {duration_minutes} minutos")
        
        # Location
        if session.get('location'):
            parts.append(f"Ubicación: {session['location']}")
        
        # Speaker
        if session.get('speaker_name'):
            parts.append(f"Ponente: {session['speaker_name']}")
            if session.get('speaker_bio'):
                parts.append(f"Sobre el ponente: {clean_text(session['speaker_bio'])}")
        
        # Tags
        if session.get('tags'):
            parts.append(f"Temas: {format_list_human(session['tags'])}")
        
        return ". ".join(parts)
    
    def generate_speaker_content(self, speaker: Dict) -> str:
        """
        Generate text content for speaker embedding
        """
        parts = []
        
        parts.append(f"Ponente: {speaker['name']}")
        
        if speaker.get('bio'):
            parts.append(f"Biografía: {clean_text(speaker['bio'])}")
        
        if speaker.get('session_names'):
            parts.append(f"Charlas: {format_list_human(speaker['session_names'])}")
        
        if speaker.get('all_tags'):
            unique_tags = list(set(speaker['all_tags']))
            parts.append(f"Áreas de expertise: {format_list_human(unique_tags)}")
        
        parts.append(f"Número de charlas: {speaker.get('session_count', 0)}")
        
        return ". ".join(parts)
    
    def process_sessions(self, sessions: List[Dict]) -> Tuple[int, int]:
        """
        Process and store session embeddings
        
        Returns:
            Tuple of (inserted_count, updated_count)
        """
        if not sessions:
            logger.info("No sessions to process")
            return 0, 0
        
        logger.info(f"Processing {len(sessions)} sessions...")
        
        # Generate contents
        contents = [self.generate_session_content(session) for session in sessions]
        
        # Get existing session IDs to determine insert vs update
        session_ids = [s['id'] for s in sessions]
        existing_ids = set()
        
        with self.dest_db:
            if session_ids:
                placeholders = ','.join(['%s'] * len(session_ids))
                result = self.dest_db.execute_query(
                    f"SELECT session_id FROM {self.config.table_names['sessions']} "
                    f"WHERE session_id IN ({placeholders})",
                    tuple(session_ids)
                )
                existing_ids = {row[0] for row in result}
        
        # Process in batches
        inserted = 0
        updated = 0
        
        with ProgressTracker(len(sessions), "Generating embeddings", logger) as tracker:
            for batch_sessions, batch_contents in zip(
                batch_iterator(sessions, self.config.embedding.batch_size),
                batch_iterator(contents, self.config.embedding.batch_size)
            ):
                # Generate embeddings
                embeddings = self.model.encode(
                    batch_contents,
                    normalize_embeddings=self.config.embedding.normalize,
                    show_progress_bar=False
                )
                
                # Validate embeddings
                if not validate_embeddings(embeddings, self.config.embedding.dimension):
                    logger.error(f"Invalid embeddings shape: {embeddings.shape}")
                    continue
                
                # Store in database
                with self.dest_db:
                    for session, content, embedding in zip(batch_sessions, batch_contents, embeddings):
                        try:
                            # Prepare data
                            speaker_names = [session['speaker_name']] if session.get('speaker_name') else []
                            
                            metadata = {
                                'event_id': session['event_id'],
                                'has_speaker': bool(session.get('speaker_name')),
                                'duration_minutes': int((
                                    datetime.combine(datetime.min, session['end_time']) - 
                                    datetime.combine(datetime.min, session['start_time'])
                                ).total_seconds() / 60),
                                'tag_count': len(session.get('tags', []))
                            }
                            
                            # Upsert
                            self.dest_db.execute_query(f"""
                                INSERT INTO {self.config.table_names['sessions']} (
                                    session_id, event_id, content, embedding,
                                    session_name, session_date, start_time, end_time,
                                    location, speaker_names, tags, metadata
                                ) VALUES (
                                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                                )
                                ON CONFLICT (session_id) DO UPDATE SET
                                    content = EXCLUDED.content,
                                    embedding = EXCLUDED.embedding,
                                    speaker_names = EXCLUDED.speaker_names,
                                    tags = EXCLUDED.tags,
                                    metadata = EXCLUDED.metadata,
                                    updated_at = CURRENT_TIMESTAMP
                            """, (
                                session['id'],
                                session['event_id'],
                                content,
                                embedding.tolist(),
                                session['name'],
                                session.get('date'),
                                session['start_time'],
                                session['end_time'],
                                session.get('location'),
                                speaker_names,
                                session.get('tags', []),
                                safe_json_dumps(metadata)
                            ))
                            
                            if session['id'] in existing_ids:
                                updated += 1
                            else:
                                inserted += 1
                                
                        except Exception as e:
                            logger.error(f"Error processing session {session['id']}: {e}")
                
                tracker.update(len(batch_sessions))
        
        logger.info(f"Sessions processed - Inserted: {inserted}, Updated: {updated}")
        return inserted, updated
    
    def process_speakers(self, speakers: List[Dict]) -> Tuple[int, int]:
        """
        Process and store speaker embeddings
        
        Returns:
            Tuple of (inserted_count, updated_count)
        """
        if not speakers:
            logger.info("No speakers to process")
            return 0, 0
        
        logger.info(f"Processing {len(speakers)} speakers...")
        
        # Generate contents
        contents = [self.generate_speaker_content(speaker) for speaker in speakers]
        
        # Get existing speaker IDs
        speaker_ids = [s['id'] for s in speakers]
        existing_ids = set()
        
        with self.dest_db:
            if speaker_ids:
                placeholders = ','.join(['%s'] * len(speaker_ids))
                result = self.dest_db.execute_query(
                    f"SELECT speaker_id FROM {self.config.table_names['speakers']} "
                    f"WHERE speaker_id IN ({placeholders})",
                    tuple(speaker_ids)
                )
                existing_ids = {row[0] for row in result}
        
        # Process in batches
        inserted = 0
        updated = 0
        
        with ProgressTracker(len(speakers), "Generating speaker embeddings", logger) as tracker:
            for batch_speakers, batch_contents in zip(
                batch_iterator(speakers, self.config.embedding.batch_size),
                batch_iterator(contents, self.config.embedding.batch_size)
            ):
                # Generate embeddings
                embeddings = self.model.encode(
                    batch_contents,
                    normalize_embeddings=self.config.embedding.normalize,
                    show_progress_bar=False
                )
                
                # Store in database
                with self.dest_db:
                    for speaker, content, embedding in zip(batch_speakers, batch_contents, embeddings):
                        try:
                            metadata = {
                                'has_bio': bool(speaker.get('bio')),
                                'unique_tag_count': len(set(speaker.get('all_tags', [])))
                            }
                            
                            self.dest_db.execute_query(f"""
                                INSERT INTO {self.config.table_names['speakers']} (
                                    speaker_id, speaker_name, content, embedding,
                                    sessions_count, session_names, all_tags, metadata
                                ) VALUES (
                                    %s, %s, %s, %s, %s, %s, %s, %s
                                )
                                ON CONFLICT (speaker_id) DO UPDATE SET
                                    content = EXCLUDED.content,
                                    embedding = EXCLUDED.embedding,
                                    sessions_count = EXCLUDED.sessions_count,
                                    session_names = EXCLUDED.session_names,
                                    all_tags = EXCLUDED.all_tags,
                                    metadata = EXCLUDED.metadata,
                                    updated_at = CURRENT_TIMESTAMP
                            """, (
                                speaker['id'],
                                speaker['name'],
                                content,
                                embedding.tolist(),
                                speaker['session_count'],
                                speaker.get('session_names', []),
                                speaker.get('all_tags', []),
                                safe_json_dumps(metadata)
                            ))
                            
                            if speaker['id'] in existing_ids:
                                updated += 1
                            else:
                                inserted += 1
                                
                        except Exception as e:
                            logger.error(f"Error processing speaker {speaker['id']}: {e}")
                
                tracker.update(len(batch_speakers))
        
        logger.info(f"Speakers processed - Inserted: {inserted}, Updated: {updated}")
        return inserted, updated
    
    def log_sync_result(self, table_name: str, start_time: datetime, 
                       processed: int, inserted: int, updated: int, 
                       status: str, error: Optional[str] = None):
        """
        Log sync result to database
        """
        execution_time = (datetime.now(timezone.utc) - start_time).total_seconds()
        
        metadata = {
            'incremental_mode': self.current_incremental_mode,
            'model': self.config.embedding.model_name,
            'device': self.config.embedding.device,
            'batch_size': self.config.embedding.batch_size
        }
        
        with self.dest_db:
            self.dest_db.execute_query(f"""
                INSERT INTO {self.config.table_names['sync_log']} (
                    table_name, records_processed, records_inserted,
                    records_updated, status, error_message,
                    execution_time_seconds, metadata
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                table_name, processed, inserted, updated,
                status, error, execution_time, safe_json_dumps(metadata)
            ))
    
    def run(self) -> bool:
        """
        Main execution method
        """
        start_time = datetime.now(timezone.utc)
        
        try:
            # Initialize
            if not self.initialize():
                return False
            
            logger.info("=" * 60)
            logger.info("Starting embeddings generation process")
            logger.info(f"Mode: {'INCREMENTAL' if self.current_incremental_mode else 'FULL'}")
            logger.info("=" * 60)
            
            # Process sessions
            with timer("Processing sessions", logger):
                sessions = self.fetch_sessions()
                sessions_inserted, sessions_updated = self.process_sessions(sessions)
                self.log_sync_result(
                    self.config.table_names['sessions'],
                    start_time,
                    len(sessions),
                    sessions_inserted,
                    sessions_updated,
                    'SUCCESS'
                )
            
            # Process speakers
            with timer("Processing speakers", logger):
                speakers = self.fetch_speakers()
                speakers_inserted, speakers_updated = self.process_speakers(speakers)
                self.log_sync_result(
                    self.config.table_names['speakers'],
                    start_time,
                    len(speakers),
                    speakers_inserted,
                    speakers_updated,
                    'SUCCESS'
                )
            
            # Summary
            total_time = (datetime.now(timezone.utc) - start_time).total_seconds()
            logger.info("=" * 60)
            logger.info("Process completed successfully!")
            logger.info(f"Total execution time: {format_duration(total_time)}")
            logger.info(f"Sessions: {len(sessions)} processed ({sessions_inserted} new, {sessions_updated} updated)")
            logger.info(f"Speakers: {len(speakers)} processed ({speakers_inserted} new, {speakers_updated} updated)")
            logger.info("=" * 60)
            
            return True
            
        except Exception as e:
            logger.error(f"Process failed: {e}", exc_info=True)
            
            # Log error
            try:
                self.log_sync_result(
                    'error',
                    start_time,
                    0, 0, 0,
                    'ERROR',
                    str(e)
                )
            except:
                pass
            
            return False
        
        finally:
            # Cleanup
            if self.source_db:
                self.source_db.close()
            if self.dest_db:
                self.dest_db.close()


def main():
    """
    Main entry point
    """
    logger.info("Event Embeddings Generator v1.0.0")
    
    generator = EmbeddingsGenerator()
    success = generator.run()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
