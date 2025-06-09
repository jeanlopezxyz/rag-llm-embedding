# src/generate_embeddings.py
import os
import sys
from datetime import datetime, timezone
from typing import Dict, List, Optional
import logging

from langchain_core.documents import Document
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_postgres import PGVector

# Asumo que tienes estos helpers en tu proyecto.
# Si los nombres o rutas son diferentes, ajústalos.
from config import config 
from utils import get_logger, timer, batch_iterator, clean_text, format_list_human, DatabaseConnection, ProgressTracker, format_duration

logger = get_logger(__name__)

class EmbeddingsGenerator:
    def __init__(self):
        self.config = config
        self.source_db: Optional[DatabaseConnection] = None
        self.vector_store: Optional[PGVector] = None
        
    def initialize(self) -> bool:
        try:
            self.source_db = DatabaseConnection(self.config.source_db.to_dict())
            
            dest = self.config.dest_db
            connection_string = f"postgresql+psycopg://{dest.user}:{dest.password}@{dest.host}:{dest.port}/{dest.dbname}"
            embeddings_model = HuggingFaceEmbeddings(model_name=self.config.embedding.model_name)
            collection_name = os.getenv('PGVECTOR_COLLECTION_NAME', 'embeddings')

            # --- ACCIÓN IMPORTANTE ---
            # Para limpiar los datos incorrectos que ya existen, forzamos la recreación de la colección.
            # Después de la primera ejecución exitosa, esta línea DEBE ser comentada o eliminada.
            self.vector_store = PGVector(
                embeddings=embeddings_model,
                collection_name=collection_name,
                connection=connection_string,
                use_jsonb=True,
                pre_delete_collection=True 
            )
            logger.info(f"✓ PGVector store listo. La colección '{collection_name}' será reseteada para asegurar datos limpios.")
            return True
        except Exception as e:
            logger.error(f"Initialization failed: {e}", exc_info=True)
            return False

    def fetch_sessions(self) -> List[Dict]:
        """
        MODIFICACIÓN: Se corrige la consulta SQL para unir correctamente las tablas
        schedules -> session_speakers -> speakers y obtener los nombres de los ponentes.
        """
        logger.info("Fetching sessions from source database...")
        query = """
            SELECT 
                s.id,
                s.session_name,
                s.start_time,
                s.end_time,
                COALESCE(r.room_name, v.venue_name, 'Sin ubicación') as location,
                s.event_id,
                array_agg(DISTINCT sp.name) FILTER (WHERE sp.name IS NOT NULL) as speaker_names,
                array_agg(DISTINCT t.tag_name) FILTER (WHERE t.tag_name IS NOT NULL) as tags
            FROM 
                schedules s
            LEFT JOIN 
                rooms r ON s.room_id = r.id
            LEFT JOIN 
                venues v ON r.venue_id = v.id
            LEFT JOIN 
                session_speakers ss ON s.id = ss.session_id
            LEFT JOIN 
                speakers sp ON ss.speaker_id = sp.id
            LEFT JOIN 
                session_tags st ON s.id = st.session_id
            LEFT JOIN 
                tags t ON st.tag_id = t.id
            GROUP BY 
                s.id, s.session_name, s.start_time, s.end_time, 
                s.event_id, r.room_name, v.venue_name
            ORDER BY 
                s.start_time
        """
        with self.source_db:
            results = self.source_db.execute_query(query)
            sessions = [{
                'id': row[0],
                'name': row[1],
                'start_time': row[2],
                'end_time': row[3],
                'location': row[4],
                'event_id': row[5],
                'speaker_names': row[6] or [], # Lista de ponentes
                'tags': row[7] or []
            } for row in results]
            logger.info(f"Se extrajeron {len(sessions)} registros de la agenda.")
            return sessions

    def generate_session_content(self, session: Dict) -> str:
        """MODIFICACIÓN: Se ajusta para manejar una lista de ponentes."""
        parts = []
        parts.append(f"Sesión: {session['name']}")
        if session.get('location'):
            parts.append(f"Ubicación: {session['location']}")
        
        if session.get('speaker_names'):
            speaker_str = format_list_human(session['speaker_names'])
            parts.append(f"Ponente(s): {speaker_str}")
            
        if session.get('tags'):
            parts.append(f"Temas: {format_list_human(session['tags'])}")
        return ". ".join(filter(None, parts))

    def process_sessions(self, sessions: List[Dict]):
        """MODIFICACIÓN: Se ajusta el metadata para guardar la lista de ponentes."""
        if not sessions: return
        
        docs_to_add, doc_ids = [], []
        for session in sessions:
            content = self.generate_session_content(session)
            metadata = {
                'source': 'sessions', 
                'session_id': session['id'],
                'name': session['name'],
                'location': session.get('location'),
                'speaker_names': session.get('speaker_names', []) 
            }
            docs_to_add.append(Document(page_content=content, metadata=metadata))
            doc_ids.append(f"session_{session['id']}")

        if docs_to_add:
            logger.info(f"Añadiendo/actualizando {len(docs_to_add)} documentos en PGVector...")
            self.vector_store.add_documents(docs_to_add, ids=doc_ids)

    def run(self):
        if not self.initialize(): return False
        with timer("Total processing time", logger):
            sessions = self.fetch_sessions()
            self.process_sessions(sessions)
        return True

if __name__ == "__main__":
    generator = EmbeddingsGenerator()
    if generator.run():
        logger.info("Proceso de generación de embeddings completado exitosamente!")
    else:
        logger.error("El proceso de generación de embeddings falló.")