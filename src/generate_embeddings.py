#!/usr/bin/env python3
"""
Generador de embeddings SIMPLIFICADO para agendas personalizadas
Versión corregida sin errores SQL
"""

import os
import sys
from datetime import datetime, timezone, time
from typing import Dict, List, Optional
import logging
import json

from langchain_core.documents import Document
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_postgres import PGVector
import psycopg

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SimpleAgendaEmbeddingsGenerator:
    """
    Generador simplificado que funciona con la estructura actual de datos.
    """
    
    def __init__(self):
        self.source_db: Optional[psycopg.Connection] = None
        self.vector_store: Optional[PGVector] = None
        
    def get_source_db_connection(self):
        """Conectar a la base de datos fuente."""
        host = os.getenv('DB_SOURCE_HOST', 'postgres-source')
        port = os.getenv('DB_SOURCE_PORT', '5432')
        database = os.getenv('DB_SOURCE_NAME', 'events_db')
        user = os.getenv('DB_SOURCE_USER', 'events_user')
        password = os.getenv('DB_SOURCE_PASSWORD', 'events_pass')
        
        logger.info(f"🔗 Conectando a DB fuente: {host}:{port}/{database}")
        
        try:
            return psycopg.connect(
                host=host, port=port, dbname=database, 
                user=user, password=password,
                connect_timeout=10
            )
        except Exception as e:
            logger.error(f"❌ Error conectando a DB fuente: {e}")
            raise e
        
    def initialize_vector_store(self) -> bool:
        """Inicializar PGVector para agendas."""
        try:
            dest_host = os.getenv('DB_DEST_HOST', 'postgres-vector')
            dest_port = os.getenv('DB_DEST_PORT', '5432')
            dest_database = os.getenv('DB_DEST_NAME', 'vector_db')
            dest_user = os.getenv('DB_DEST_USER', 'vector_user')
            dest_password = os.getenv('DB_DEST_PASSWORD', 'vector_pass')
            
            connection_string = f"postgresql+psycopg://{dest_user}:{dest_password}@{dest_host}:{dest_port}/{dest_database}"
            
            logger.info(f"🔗 Conectando PGVector: {dest_host}:{dest_port}/{dest_database}")
            
            embedding_model = os.getenv('EMBEDDING_MODEL_NAME', 'sentence-transformers/multi-qa-mpnet-base-dot-v1')
            encode_kwargs = {'normalize_embeddings': True}
            
            embeddings_model = HuggingFaceEmbeddings(
                model_name=embedding_model,
                encode_kwargs=encode_kwargs
            )
            
            collection_name = 'agenda_sessions'

            self.vector_store = PGVector(
                embeddings=embeddings_model,
                collection_name=collection_name,
                connection=connection_string,
                use_jsonb=True,
                pre_delete_collection=True
            )
            
            logger.info(f"✅ PGVector inicializado. Colección '{collection_name}' para agendas.")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error inicializando PGVector: {e}")
            return False

    def fetch_simple_sessions(self) -> List[Dict]:
        """
        Obtener sesiones con consulta SQL simplificada que funciona.
        """
        logger.info("🔍 Obteniendo sesiones con consulta simplificada...")
        
        # Consulta SQL simplificada sin ORDER BY problemáticos
        query = """
        SELECT 
            s.id,
            s.session_name,
            s.session_type,
            s.session_date,
            s.start_time,
            s.end_time,
            EXTRACT(EPOCH FROM (s.end_time - s.start_time))/60 as duration_minutes,
            EXTRACT(HOUR FROM s.start_time) as start_hour,
            EXTRACT(MINUTE FROM s.start_time) as start_minute,
            
            -- Información del evento
            e.event_name,
            e.location,
            e.venue_name,
            e.venue_address,
            
            -- Track
            t.track_name,
            t.track_description,
            
            -- Ubicación
            r.room_code,
            r.room_name,
            v.venue_name as sala_venue,
            v.capacity,
            
            -- URLs
            s.slides_url,
            s.repository_url
            
        FROM schedules s
        LEFT JOIN events e ON s.event_id = e.id
        LEFT JOIN rooms r ON s.room_id = r.id
        LEFT JOIN venues v ON r.venue_id = v.id
        LEFT JOIN tracks t ON s.track_id = t.id
        ORDER BY s.session_date, s.start_time, s.id;
        """
        
        try:
            with self.get_source_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(query)
                    results = cur.fetchall()
                    
                    sessions = []
                    for row in results:
                        session = {
                            'id': row[0],
                            'session_name': row[1] or f'Sesión {row[0]}',
                            'session_type': row[2] or 'charla',
                            'session_date': row[3],
                            'start_time': row[4],
                            'end_time': row[5],
                            'duration_minutes': row[6] or 60,
                            'start_hour': int(row[7]) if row[7] else 9,
                            'start_minute': int(row[8]) if row[8] else 0,
                            'event_name': row[9] or 'KCD Antigua Guatemala 2025',
                            'location': row[10] or 'Antigua Guatemala',
                            'venue_name': row[11] or 'Centro de Convenciones Antigua',
                            'venue_address': row[12] or 'Antigua Guatemala, Guatemala',
                            'track_name': row[13] or 'General',
                            'track_description': row[14] or 'Track general',
                            'room_code': row[15] or 'ROOM-1',
                            'room_name': row[16] or 'Sala Principal',
                            'sala_venue': row[17] or 'Auditorium',
                            'capacity': row[18] or 200,
                            'slides_url': row[19],
                            'repository_url': row[20]
                        }
                        sessions.append(session)
                    
                    logger.info(f"✅ Obtenidas {len(sessions)} sesiones básicas")
                    return sessions
                    
        except Exception as e:
            logger.error(f"❌ Error obteniendo sesiones: {e}")
            return []

    def fetch_speakers_for_sessions(self, sessions: List[Dict]) -> List[Dict]:
        """
        Obtener información de speakers por separado para evitar problemas de agregación.
        """
        logger.info("👥 Obteniendo información de speakers...")
        
        if not sessions:
            return sessions
        
        session_ids = [s['id'] for s in sessions]
        placeholders = ','.join(['%s'] * len(session_ids))
        
        speaker_query = f"""
        SELECT 
            ss.session_id,
            sp.name,
            sp.company
        FROM session_speakers ss
        JOIN speakers sp ON ss.speaker_id = sp.id
        WHERE ss.session_id IN ({placeholders})
        ORDER BY ss.session_id, ss.speaker_order;
        """
        
        try:
            with self.get_source_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(speaker_query, session_ids)
                    speaker_results = cur.fetchall()
                    
                    # Organizar speakers por session_id
                    speakers_by_session = {}
                    for row in speaker_results:
                        session_id = row[0]
                        speaker_name = row[1]
                        company = row[2]
                        
                        if session_id not in speakers_by_session:
                            speakers_by_session[session_id] = []
                        
                        speaker_info = speaker_name
                        if company:
                            speaker_info += f" ({company})"
                        
                        speakers_by_session[session_id].append({
                            'name': speaker_name,
                            'company': company,
                            'full_info': speaker_info
                        })
                    
                    # Agregar información de speakers a las sesiones
                    for session in sessions:
                        session_id = session['id']
                        session_speakers = speakers_by_session.get(session_id, [])
                        
                        if session_speakers:
                            session['speakers_info'] = ', '.join([s['full_info'] for s in session_speakers])
                            session['speaker_names_only'] = ', '.join([s['name'] for s in session_speakers])
                            session['speaker_companies'] = ', '.join([s['company'] for s in session_speakers if s['company']])
                        else:
                            session['speakers_info'] = 'Speaker por determinar'
                            session['speaker_names_only'] = ''
                            session['speaker_companies'] = ''
                    
                    logger.info(f"✅ Información de speakers agregada a {len(sessions)} sesiones")
                    return sessions
                    
        except Exception as e:
            logger.error(f"❌ Error obteniendo speakers: {e}")
            # Devolver sesiones con información por defecto
            for session in sessions:
                session['speakers_info'] = 'Speaker por determinar'
                session['speaker_names_only'] = ''
                session['speaker_companies'] = ''
            return sessions

    def fetch_tags_for_sessions(self, sessions: List[Dict]) -> List[Dict]:
        """
        Obtener tags por separado para evitar problemas de agregación.
        """
        logger.info("🏷️ Obteniendo tags de sesiones...")
        
        if not sessions:
            return sessions
        
        session_ids = [s['id'] for s in sessions]
        placeholders = ','.join(['%s'] * len(session_ids))
        
        tags_query = f"""
        SELECT 
            st.session_id,
            tg.tag_name,
            tg.tag_description
        FROM session_tags st
        JOIN tags tg ON st.tag_id = tg.id
        WHERE st.session_id IN ({placeholders});
        """
        
        try:
            with self.get_source_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(tags_query, session_ids)
                    tag_results = cur.fetchall()
                    
                    # Organizar tags por session_id
                    tags_by_session = {}
                    for row in tag_results:
                        session_id = row[0]
                        tag_name = row[1]
                        tag_description = row[2]
                        
                        if session_id not in tags_by_session:
                            tags_by_session[session_id] = []
                        
                        tags_by_session[session_id].append({
                            'name': tag_name,
                            'description': tag_description
                        })
                    
                    # Agregar información de tags a las sesiones
                    for session in sessions:
                        session_id = session['id']
                        session_tags = tags_by_session.get(session_id, [])
                        
                        if session_tags:
                            session['session_tags'] = ', '.join([t['name'] for t in session_tags])
                            session['tag_descriptions'] = '; '.join([t['description'] for t in session_tags if t['description']])
                        else:
                            session['session_tags'] = 'General'
                            session['tag_descriptions'] = ''
                    
                    logger.info(f"✅ Tags agregados a {len(sessions)} sesiones")
                    return sessions
                    
        except Exception as e:
            logger.error(f"❌ Error obteniendo tags: {e}")
            # Devolver sesiones con información por defecto
            for session in sessions:
                session['session_tags'] = 'General'
                session['tag_descriptions'] = ''
            return sessions

    def generate_agenda_content(self, session: Dict) -> str:
        """
        Generar contenido optimizado para agendas con datos disponibles.
        """
        content_parts = []
        
        # 1. Información básica del evento
        content_parts.append(f"EVENTO: {session.get('event_name', 'KCD Antigua Guatemala 2025')}")
        content_parts.append(f"UBICACIÓN DEL EVENTO: {session.get('venue_name', 'Centro de Convenciones Antigua')}, {session.get('venue_address', 'Antigua Guatemala')}")
        
        # 2. Información de la sesión
        content_parts.append(f"SESIÓN: {session['session_name']}")
        
        session_type_map = {
            'charla': 'Charla técnica',
            'workshop': 'Taller práctico', 
            'sponsored': 'Presentación patrocinada',
            'keynote': 'Charla magistral'
        }
        session_type = session_type_map.get(session.get('session_type', '').lower(), session.get('session_type', 'Presentación'))
        content_parts.append(f"TIPO DE SESIÓN: {session_type}")
        
        # 3. Información de speakers
        content_parts.append(f"PONENTE(S): {session.get('speakers_info', 'Speaker por determinar')}")
        
        if session.get('speaker_companies'):
            content_parts.append(f"EMPRESAS: {session['speaker_companies']}")
        
        # 4. Información temporal CRÍTICA para agendas
        if session['start_time'] and session['end_time']:
            # El evento es el 14 de junio de 2025
            date_str = "14 de junio de 2025"
            start_time_str = session['start_time'].strftime('%H:%M') if session['start_time'] else 'Hora por definir'
            end_time_str = session['end_time'].strftime('%H:%M') if session['end_time'] else 'Fin por definir'
            
            content_parts.append(f"FECHA: {date_str}")
            content_parts.append(f"HORARIO: de {start_time_str} a {end_time_str}")
            content_parts.append(f"DURACIÓN: {int(session.get('duration_minutes', 60))} minutos")
            
            # Contexto temporal para filtros
            start_hour = session.get('start_hour', 9)
            if 9 <= start_hour < 12:
                content_parts.append("PERÍODO DEL DÍA: Mañana (09:00-12:00)")
            elif 12 <= start_hour < 14:
                content_parts.append("PERÍODO DEL DÍA: Mediodía (12:00-14:00)")
            elif 14 <= start_hour < 17:
                content_parts.append("PERÍODO DEL DÍA: Tarde (14:00-17:00)")
            
            # Información numérica para algoritmos
            content_parts.append(f"HORA INICIO NUMÉRICA: {start_hour:02d}:{session.get('start_minute', 0):02d}")
        
        # 5. Ubicación específica
        content_parts.append(f"SALA: {session.get('room_name', 'Sala Principal')}")
        content_parts.append(f"CÓDIGO SALA: {session.get('room_code', 'ROOM-1')}")
        content_parts.append(f"CAPACIDAD: {session.get('capacity', 200)} personas")
        
        # 6. Track y categorización
        track_name = session.get('track_name', 'General')
        content_parts.append(f"TRACK: {track_name}")
        content_parts.append(f"DESCRIPCIÓN DEL TRACK: {session.get('track_description', 'Track general')}")
        
        # 7. Tags y tecnologías
        session_tags = session.get('session_tags', 'General')
        content_parts.append(f"TECNOLOGÍAS Y TEMAS: {session_tags}")
        
        if session.get('tag_descriptions'):
            content_parts.append(f"DESCRIPCIÓN DE TECNOLOGÍAS: {session['tag_descriptions']}")
        
        # 8. Recursos disponibles
        resources = []
        if session.get('slides_url'):
            resources.append("Slides de presentación")
        if session.get('repository_url'):
            resources.append("Código fuente en GitHub")
        
        if resources:
            content_parts.append(f"RECURSOS DISPONIBLES: {', '.join(resources)}")
        
        # 9. Información para agendas personalizadas
        content_parts.append("DISPONIBLE PARA AGENDA PERSONALIZADA: Sí")
        content_parts.append("SIN CONFLICTOS TEMPORALES: Verificar con otras sesiones seleccionadas")
        content_parts.append("IDIOMA: Español")
        content_parts.append("MODALIDAD: Presencial")
        content_parts.append("REGISTRO: Gratuito con inscripción previa")
        content_parts.append("COMUNIDAD: CNCF (Cloud Native Computing Foundation)")
        
        # 10. Categorización para filtros
        duration = session.get('duration_minutes', 60)
        if duration <= 30:
            duration_cat = "Corta (hasta 30 min)"
        elif duration <= 60:
            duration_cat = "Media (31-60 min)"
        else:
            duration_cat = "Larga (más de 60 min)"
        
        content_parts.append(f"DURACIÓN CATEGÓRICA: {duration_cat}")
        
        # Nivel sugerido basado en contenido
        session_name_lower = session['session_name'].lower()
        if '101' in session_name_lower or 'básico' in session_name_lower:
            level = "Principiante"
        elif 'avanzado' in session_name_lower or 'enterprise' in session_name_lower:
            level = "Avanzado"
        else:
            level = "Intermedio"
        
        content_parts.append(f"NIVEL SUGERIDO: {level}")
        
        return ". ".join(content_parts)

    def clean_session_data(self, sessions: List[Dict]) -> List[Dict]:
        """
        Limpiar datos de sesiones para evitar errores de serialización.
        """
        logger.info("🧹 Limpiando datos de sesiones...")
        
        cleaned_sessions = []
        for session in sessions:
            cleaned_session = {}
            for key, value in session.items():
                if value is None:
                    cleaned_session[key] = None
                elif isinstance(value, (int, str, bool)):
                    cleaned_session[key] = value
                elif hasattr(value, 'isoformat'):  # datetime objects
                    cleaned_session[key] = value
                else:
                    # Convertir Decimal y otros tipos a float/int/str
                    try:
                        if str(type(value)).startswith('<class \'decimal.Decimal'):
                            cleaned_session[key] = float(value)
                        else:
                            cleaned_session[key] = str(value)
                    except:
                        cleaned_session[key] = str(value)
            
            cleaned_sessions.append(cleaned_session)
        
        logger.info(f"✅ Limpiados {len(cleaned_sessions)} sesiones")
        return cleaned_sessions

    def process_sessions_for_agenda(self, sessions: List[Dict]):
        """Procesar sesiones para agendas personalizadas."""
        if not sessions:
            logger.warning("⚠️ No hay sesiones para procesar")
            return
        
        docs_to_add = []
        doc_ids = []
        
        logger.info(f"🔄 Procesando {len(sessions)} sesiones para agendas personalizadas...")
        
        for session in sessions:
            # Generar contenido optimizado
            agenda_content = self.generate_agenda_content(session)
            
            # Metadata para agendas (con conversión de tipos)
            metadata = {
                'source': 'kcd_antigua_2025_agenda',
                'session_id': int(session['id']),
                'session_name': str(session['session_name']),
                'session_type': str(session['session_type']),
                'track_name': str(session.get('track_name', '')),
                'speakers_info': str(session.get('speakers_info', '')),
                'speaker_names_only': str(session.get('speaker_names_only', '')),
                'speaker_companies': str(session.get('speaker_companies', '')),
                
                # Temporal info (convertir a tipos JSON serializables)
                'session_date': session['session_date'].isoformat() if session['session_date'] else '2025-06-14',
                'start_time': session['start_time'].isoformat() if session['start_time'] else None,
                'end_time': session['end_time'].isoformat() if session['end_time'] else None,
                'start_hour': int(session.get('start_hour', 9)),
                'start_minute': int(session.get('start_minute', 0)),
                'duration_minutes': float(session.get('duration_minutes', 60.0)),
                
                # Location
                'room_name': str(session.get('room_name', '')),
                'room_code': str(session.get('room_code', '')),
                'capacity': int(session.get('capacity', 200)),
                
                # Categorization
                'session_tags': str(session.get('session_tags', '')),
                'period_of_day': str(self._get_period_of_day(session.get('start_hour', 9))),
                'duration_category': str(self._categorize_duration(float(session.get('duration_minutes', 60.0)))),
                'suggested_level': str(self._suggest_level(session['session_name'])),
                
                # Event info
                'event_name': str(session.get('event_name', 'KCD Antigua Guatemala 2025')),
                'location': str(session.get('location', 'Antigua Guatemala')),
                'venue_name': str(session.get('venue_name', 'Centro de Convenciones Antigua')),
                'language': 'Español',
                'is_free': True,
                'requires_registration': True,
                'is_online': False,
                
                # Resources
                'has_slides': bool(session.get('slides_url')),
                'has_repository': bool(session.get('repository_url')),
                'slides_url': str(session.get('slides_url', '') if session.get('slides_url') else ''),
                'repository_url': str(session.get('repository_url', '') if session.get('repository_url') else '')
            }
            
            # Crear documento
            doc = Document(page_content=agenda_content, metadata=metadata)
            docs_to_add.append(doc)
            doc_ids.append(f"agenda_session_{session['id']}")
            
            # Log de ejemplo
            if session['id'] <= 3:
                logger.info(f"📄 Ejemplo sesión {session['id']}:")
                logger.info(f"   Nombre: {session['session_name']}")
                logger.info(f"   Speakers: {session.get('speakers_info', 'N/A')}")
                logger.info(f"   Tags: {session.get('session_tags', 'N/A')}")

        # Agregar a PGVector
        if docs_to_add:
            logger.info(f"⬆️ Agregando {len(docs_to_add)} documentos para agendas...")
            self.vector_store.add_documents(docs_to_add, ids=doc_ids)
            logger.info("✅ Embeddings para agendas creados exitosamente")

    def _get_period_of_day(self, start_hour: int) -> str:
        """Determinar período del día."""
        if 9 <= start_hour < 12:
            return 'mañana'
        elif 12 <= start_hour < 14:
            return 'mediodía'
        elif 14 <= start_hour < 17:
            return 'tarde'
        else:
            return 'otro'

    def _categorize_duration(self, duration_minutes: int) -> str:
        """Categorizar duración."""
        if duration_minutes <= 30:
            return "Corta"
        elif duration_minutes <= 60:
            return "Media"
        else:
            return "Larga"

    def _suggest_level(self, session_name: str) -> str:
        """Sugerir nivel basado en nombre."""
        name_lower = session_name.lower()
        if '101' in name_lower or 'básico' in name_lower:
            return "Principiante"
        elif 'avanzado' in name_lower or 'enterprise' in name_lower:
            return "Avanzado"
        else:
            return "Intermedio"

    def test_agenda_search(self):
        """Probar búsquedas básicas."""
        logger.info("🧪 Probando búsquedas para agendas...")
        
        test_queries = [
            "agenda kubernetes",
            "charlas mañana",
            "sesiones seguridad",
            "agenda devops",
            "horarios disponibles"
        ]
        
        for query in test_queries:
            try:
                results = self.vector_store.similarity_search(query, k=3)
                logger.info(f"🔍 '{query}': {len(results)} resultados")
                
                for i, doc in enumerate(results):
                    session_name = doc.metadata.get('session_name', 'Sin nombre')
                    start_time = doc.metadata.get('start_time', 'Sin horario')
                    
                    logger.info(f"   {i+1}. {session_name} - {start_time}")
                    
            except Exception as e:
                logger.error(f"❌ Error probando '{query}': {e}")

    def run(self):
        """Ejecutar el proceso completo."""
        logger.info("🚀 INICIANDO GENERACIÓN DE EMBEDDINGS SIMPLIFICADOS PARA AGENDAS")
        logger.info("=" * 70)
        
        # 1. Inicializar vector store
        if not self.initialize_vector_store():
            logger.error("❌ Falló la inicialización del vector store")
            return False
        
        # 2. Obtener sesiones básicas
        sessions = self.fetch_simple_sessions()
        if not sessions:
            logger.error("❌ No se pudieron obtener las sesiones")
            return False
        
        # 3. Limpiar datos para evitar errores de serialización
        sessions = self.clean_session_data(sessions)
        
        # 4. Agregar información de speakers
        sessions = self.fetch_speakers_for_sessions(sessions)
        
        # 5. Agregar información de tags
        sessions = self.fetch_tags_for_sessions(sessions)
        
        # 6. Procesar para agendas
        self.process_sessions_for_agenda(sessions)
        
        # 7. Probar búsquedas
        self.test_agenda_search()
        
        logger.info("✅ Proceso de embeddings para agendas completado")
        return True

if __name__ == "__main__":
    generator = SimpleAgendaEmbeddingsGenerator()
    success = generator.run()
    
    if success:
        print("\n🎉 ¡EMBEDDINGS PARA AGENDAS GENERADOS EXITOSAMENTE!")
        print("\n📋 CONFIGURACIÓN NECESARIA:")
        print("1. Actualiza: PGVECTOR_COLLECTION_NAME=agenda_sessions")
        print("2. Usa el query helper mejorado para agendas")
        print("3. Reinicia la aplicación")
        
        print("\n🎯 PRUEBA CON:")
        print("• 'Crea una agenda sobre kubernetes'")
        print("• 'Agenda de la mañana sin conflictos'")
        print("• 'Planifica charlas de seguridad'")
    else:
        print("❌ Falló la generación de embeddings")
        sys.exit(1)