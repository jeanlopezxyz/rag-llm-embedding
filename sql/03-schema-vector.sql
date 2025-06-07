-- sql/03-schema-vector.sql
-- Schema completo para PGVector

-- ============================================
-- EXTENSIONES
-- ============================================
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ============================================
-- FUNCIONES COMUNES
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- TABLAS DE EMBEDDINGS
-- ============================================

-- Tabla de embeddings de sesiones
CREATE TABLE IF NOT EXISTS session_embeddings (
    id SERIAL PRIMARY KEY,
    session_id INTEGER UNIQUE NOT NULL,
    event_id INTEGER NOT NULL,
    
    -- Contenido y embedding
    content TEXT NOT NULL,
    embedding vector(768),
    
    -- Campos para búsquedas y filtros
    session_name VARCHAR(500) NOT NULL,
    session_date DATE,
    start_time TIME,
    end_time TIME,
    location VARCHAR(255),
    speaker_names TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    
    -- Metadata adicional
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de embeddings de speakers
CREATE TABLE IF NOT EXISTS speaker_embeddings (
    id SERIAL PRIMARY KEY,
    speaker_id INTEGER UNIQUE NOT NULL,
    speaker_name VARCHAR(255) NOT NULL,
    
    -- Contenido y embedding
    content TEXT NOT NULL,
    embedding vector(768),
    
    -- Información adicional
    sessions_count INTEGER DEFAULT 0,
    session_names TEXT[] DEFAULT '{}',
    all_tags TEXT[] DEFAULT '{}',
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de logs de sincronización
CREATE TABLE IF NOT EXISTS embeddings_sync_log (
    id SERIAL PRIMARY KEY,
    sync_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(50),
    records_processed INTEGER DEFAULT 0,
    records_inserted INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    status VARCHAR(20),
    error_message TEXT,
    execution_time_seconds NUMERIC(10,2),
    metadata JSONB DEFAULT '{}'
);

-- ============================================
-- ÍNDICES
-- ============================================

-- Índices HNSW para búsquedas vectoriales
CREATE INDEX IF NOT EXISTS idx_session_embeddings_vector
ON session_embeddings USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS idx_speaker_embeddings_vector
ON speaker_embeddings USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Índices para búsquedas por campos
CREATE INDEX IF NOT EXISTS idx_session_embeddings_date_time 
ON session_embeddings(session_date, start_time, end_time);

CREATE INDEX IF NOT EXISTS idx_session_embeddings_location 
ON session_embeddings(location);

CREATE INDEX IF NOT EXISTS idx_session_embeddings_event 
ON session_embeddings(event_id);

-- Índices GIN para arrays
CREATE INDEX IF NOT EXISTS idx_session_embeddings_speakers 
ON session_embeddings USING GIN(speaker_names);

CREATE INDEX IF NOT EXISTS idx_session_embeddings_tags 
ON session_embeddings USING GIN(tags);

CREATE INDEX IF NOT EXISTS idx_speaker_embeddings_tags 
ON speaker_embeddings USING GIN(all_tags);

-- Índices para metadata JSONB
CREATE INDEX IF NOT EXISTS idx_session_embeddings_metadata 
ON session_embeddings USING GIN(metadata);

CREATE INDEX IF NOT EXISTS idx_speaker_embeddings_metadata 
ON speaker_embeddings USING GIN(metadata);

-- ============================================
-- TRIGGERS
-- ============================================

-- Triggers para actualizar updated_at
CREATE TRIGGER update_session_embeddings_updated_at 
BEFORE UPDATE ON session_embeddings 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_speaker_embeddings_updated_at 
BEFORE UPDATE ON speaker_embeddings 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCIONES DE BÚSQUEDA
-- ============================================

-- Función para buscar sesiones similares
CREATE OR REPLACE FUNCTION search_similar_sessions(
    query_embedding vector(768),
    limit_count INTEGER DEFAULT 10,
    threshold FLOAT DEFAULT 0.7
) RETURNS TABLE(
    session_id INTEGER,
    session_name VARCHAR,
    similarity_score FLOAT,
    session_date DATE,
    start_time TIME,
    location VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        se.session_id,
        se.session_name,
        1 - (se.embedding <=> query_embedding) AS similarity_score,
        se.session_date,
        se.start_time,
        se.location
    FROM session_embeddings se
    WHERE se.embedding IS NOT NULL
    AND 1 - (se.embedding <=> query_embedding) >= threshold
    ORDER BY similarity_score DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Función para buscar sesiones por speaker
CREATE OR REPLACE FUNCTION search_sessions_by_speaker(
    speaker_name_search TEXT
) RETURNS TABLE(
    session_id INTEGER,
    session_name VARCHAR,
    session_date DATE,
    start_time TIME,
    end_time TIME,
    location VARCHAR,
    matched_speaker TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        se.session_id,
        se.session_name,
        se.session_date,
        se.start_time,
        se.end_time,
        se.location,
        speaker_name
    FROM session_embeddings se
    CROSS JOIN LATERAL unnest(se.speaker_names) AS speaker_name
    WHERE speaker_name ILIKE '%' || speaker_name_search || '%'
    ORDER BY se.session_date, se.start_time;
END;
$$ LANGUAGE plpgsql;

-- Función para buscar sesiones por tags
CREATE OR REPLACE FUNCTION search_sessions_by_tag(
    tag_search TEXT
) RETURNS TABLE(
    session_id INTEGER,
    session_name VARCHAR,
    session_date DATE,
    start_time TIME,
    location VARCHAR,
    matched_tag TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        se.session_id,
        se.session_name,
        se.session_date,
        se.start_time,
        se.location,
        tag
    FROM session_embeddings se
    CROSS JOIN LATERAL unnest(se.tags) AS tag
    WHERE tag ILIKE '%' || tag_search || '%'
    ORDER BY se.session_date, se.start_time;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista de estadísticas de embeddings
CREATE OR REPLACE VIEW v_embeddings_stats AS
SELECT 
    'session_embeddings' as table_name,
    COUNT(*) as total_records,
    COUNT(embedding) as embeddings_count,
    ROUND(AVG(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) as completeness_pct,
    MAX(updated_at) as last_updated
FROM session_embeddings
UNION ALL
SELECT 
    'speaker_embeddings' as table_name,
    COUNT(*) as total_records,
    COUNT(embedding) as embeddings_count,
    ROUND(AVG(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END) * 100, 2) as completeness_pct,
    MAX(updated_at) as last_updated
FROM speaker_embeddings;

-- Vista de últimas sincronizaciones
CREATE OR REPLACE VIEW v_recent_syncs AS
SELECT 
    sync_timestamp,
    table_name,
    records_processed,
    records_inserted,
    records_updated,
    status,
    execution_time_seconds,
    CASE 
        WHEN execution_time_seconds > 0 
        THEN ROUND(records_processed::numeric / execution_time_seconds, 2)
        ELSE 0 
    END as records_per_second
FROM embeddings_sync_log
ORDER BY sync_timestamp DESC
LIMIT 20;

-- ============================================
-- PERMISOS (ajustar según tu configuración)
-- ============================================
-- GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO vector_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO vector_user;
