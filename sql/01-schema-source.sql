-- sql/01-schema-source.sql
-- ============================================
-- SCHEMA POSTGRESQL COMPLETO - SISTEMA SIMPLIFICADO
-- Base de datos fuente para un solo evento
-- ============================================

-- Eliminar tablas si existen (para empezar limpio)
DROP TABLE IF EXISTS session_resources CASCADE;
DROP TABLE IF EXISTS session_tags CASCADE;
DROP TABLE IF EXISTS session_speakers CASCADE;
DROP TABLE IF EXISTS schedules CASCADE;
DROP TABLE IF EXISTS speakers CASCADE;
DROP TABLE IF EXISTS sponsors CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS venues CASCADE;
DROP TABLE IF EXISTS tracks CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS events CASCADE;

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

-- Tabla de Evento (solo uno)
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    event_name VARCHAR(255) NOT NULL,
    event_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description TEXT,
    location VARCHAR(255),
    venue_name VARCHAR(255),
    venue_address TEXT,
    max_attendees INTEGER,
    website_url VARCHAR(2083),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Tags/Temas
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    tag_name VARCHAR(100) UNIQUE NOT NULL,
    tag_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Tracks/Categorías principales
CREATE TABLE tracks (
    id SERIAL PRIMARY KEY,
    track_name VARCHAR(100) NOT NULL,
    track_description TEXT,
    color_hex VARCHAR(7),
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Ubicaciones/Salas
CREATE TABLE venues (
    id SERIAL PRIMARY KEY,
    venue_name VARCHAR(255) NOT NULL,
    venue_type VARCHAR(50),
    capacity INTEGER,
    floor VARCHAR(50),
    amenities TEXT[],
    accessibility_features TEXT[],
    location_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Rooms
CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    venue_id INTEGER REFERENCES venues(id) ON DELETE CASCADE,
    room_code VARCHAR(50) UNIQUE NOT NULL,
    room_name VARCHAR(255) NOT NULL,
    capacity INTEGER,
    setup_style VARCHAR(50),
    equipment TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Speakers/Ponentes
CREATE TABLE speakers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    title VARCHAR(255),
    company VARCHAR(255),
    email VARCHAR(255),
    profile_picture_url VARCHAR(2083),
    expertise_areas TEXT[],
    social_links JSONB DEFAULT '{}',
    is_keynote BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Sponsors
CREATE TABLE sponsors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    logo_url VARCHAR(2083),
    website_url VARCHAR(2083),
    sponsor_level VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Sesiones/Charlas
CREATE TABLE schedules (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    session_code VARCHAR(50) UNIQUE,
    session_name VARCHAR(255) NOT NULL,
    session_description TEXT,
    session_type VARCHAR(50) NOT NULL,
    session_format VARCHAR(50),
    difficulty_level VARCHAR(20),
    language VARCHAR(20) DEFAULT 'español',
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_minutes INTEGER GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (end_time - start_time))/60) STORED,
    room_id INTEGER REFERENCES rooms(id),
    is_online BOOLEAN DEFAULT FALSE,
    streaming_url VARCHAR(2083),
    track_id INTEGER REFERENCES tracks(id),
    target_audience TEXT[],
    prerequisites TEXT,
    required_tools TEXT[],
    max_attendees INTEGER,
    requires_registration BOOLEAN DEFAULT FALSE,
    materials_url VARCHAR(2083),
    slides_url VARCHAR(2083),
    recording_url VARCHAR(2083),
    repository_url VARCHAR(2083),
    tags TEXT[],
    search_vector tsvector,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- Campo legacy para compatibilidad
    speaker_id INTEGER REFERENCES speakers(id)
);

-- ============================================
-- TABLAS DE RELACIÓN
-- ============================================

-- Relación muchos a muchos: Sesiones <-> Speakers
CREATE TABLE session_speakers (
    session_id INTEGER NOT NULL REFERENCES schedules(id) ON DELETE CASCADE,
    speaker_id INTEGER NOT NULL REFERENCES speakers(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'speaker',
    is_primary BOOLEAN DEFAULT FALSE,
    speaker_order INTEGER DEFAULT 0,
    PRIMARY KEY (session_id, speaker_id)
);

-- Relación muchos a muchos: Sesiones <-> Tags
CREATE TABLE session_tags (
    session_id INTEGER NOT NULL REFERENCES schedules(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    relevance_score FLOAT DEFAULT 1.0,
    PRIMARY KEY (session_id, tag_id)
);

-- Recursos adicionales por sesión
CREATE TABLE session_resources (
    id SERIAL PRIMARY KEY,
    session_id INTEGER NOT NULL REFERENCES schedules(id) ON DELETE CASCADE,
    resource_type VARCHAR(50) NOT NULL,
    resource_name VARCHAR(255) NOT NULL,
    resource_url VARCHAR(2083),
    resource_description TEXT,
    file_size_mb FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

CREATE INDEX idx_schedules_event ON schedules(event_id);
CREATE INDEX idx_schedules_date_time ON schedules(session_date, start_time);
CREATE INDEX idx_schedules_room ON schedules(room_id);
CREATE INDEX idx_schedules_track ON schedules(track_id);
CREATE INDEX idx_schedules_type ON schedules(session_type);
CREATE INDEX idx_schedules_level ON schedules(difficulty_level);
CREATE INDEX idx_schedules_search ON schedules USING GIN(search_vector);
CREATE INDEX idx_schedules_tags ON schedules USING GIN(tags);
CREATE INDEX idx_speakers_expertise ON speakers USING GIN(expertise_areas);
CREATE INDEX idx_session_speakers_session ON session_speakers(session_id);
CREATE INDEX idx_session_speakers_speaker ON session_speakers(speaker_id);
CREATE INDEX idx_session_tags_session ON session_tags(session_id);
CREATE INDEX idx_session_tags_tag ON session_tags(tag_id);

-- ============================================
-- VISTAS ÚTILES
-- ============================================

-- Vista completa de sesiones (CORREGIDA)
CREATE OR REPLACE VIEW v_session_full_details AS
SELECT 
    s.id AS session_id,
    s.session_code,
    s.session_name,
    s.session_description,
    s.session_type,
    s.session_format,
    s.difficulty_level,
    s.language,
    s.session_date,
    s.start_time,
    s.end_time,
    s.duration_minutes,
    r.room_code,
    r.room_name,
    v.venue_name,
    v.floor,
    t.track_name,
    t.color_hex AS track_color,
    s.max_attendees,
    s.requires_registration,
    s.is_online,
    s.streaming_url,
    -- Agregación de speakers (sin ORDER BY en json_agg con DISTINCT)
    COALESCE(
        json_agg(
            DISTINCT jsonb_build_object(
                'id', sp.id,
                'name', sp.name,
                'title', sp.title,
                'company', sp.company,
                'role', ss.role,
                'is_primary', ss.is_primary,
                'order', ss.speaker_order
            )
        ) FILTER (WHERE sp.id IS NOT NULL), 
        '[]'::json
    ) AS speakers,
    -- Agregación de tags
    COALESCE(
        array_agg(
            DISTINCT tg.tag_name
        ) FILTER (WHERE tg.id IS NOT NULL), 
        ARRAY[]::text[]
    ) AS session_tags,
    -- URLs de materiales
    json_build_object(
        'materials', s.materials_url,
        'slides', s.slides_url,
        'recording', s.recording_url,
        'repository', s.repository_url
    ) AS resources
FROM schedules s
LEFT JOIN rooms r ON s.room_id = r.id
LEFT JOIN venues v ON r.venue_id = v.id
LEFT JOIN tracks t ON s.track_id = t.id
LEFT JOIN session_speakers ss ON s.id = ss.session_id
LEFT JOIN speakers sp ON ss.speaker_id = sp.id
LEFT JOIN session_tags st ON s.id = st.session_id
LEFT JOIN tags tg ON st.tag_id = tg.id
GROUP BY 
    s.id, s.session_code, s.session_name, s.session_description,
    s.session_type, s.session_format, s.difficulty_level, s.language,
    s.session_date, s.start_time, s.end_time, s.duration_minutes,
    r.room_code, r.room_name, v.venue_name, v.floor,
    t.track_name, t.color_hex, s.max_attendees, s.requires_registration,
    s.is_online, s.streaming_url, s.materials_url, s.slides_url,
    s.recording_url, s.repository_url;

-- Vista de agenda por día
CREATE OR REPLACE VIEW v_daily_agenda AS
SELECT 
    s.session_date,
    s.start_time,
    s.end_time,
    s.session_name,
    s.session_type,
    r.room_name,
    t.track_name,
    string_agg(sp.name, ', ' ORDER BY ss.speaker_order) AS speakers
FROM schedules s
LEFT JOIN rooms r ON s.room_id = r.id
LEFT JOIN tracks t ON s.track_id = t.id
LEFT JOIN session_speakers ss ON s.id = ss.session_id
LEFT JOIN speakers sp ON ss.speaker_id = sp.id
GROUP BY 
    s.session_date, s.start_time, s.end_time, s.session_name,
    s.session_type, r.room_name, t.track_name
ORDER BY s.session_date, s.start_time;

-- ============================================
-- TRIGGERS
-- ============================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a tablas con updated_at
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_speakers_updated_at BEFORE UPDATE ON speakers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para actualizar search_vector
CREATE OR REPLACE FUNCTION update_schedule_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('spanish', COALESCE(NEW.session_name, '')), 'A') ||
        setweight(to_tsvector('spanish', COALESCE(NEW.session_description, '')), 'B') ||
        setweight(to_tsvector('spanish', COALESCE(array_to_string(NEW.tags, ' '), '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_schedule_search_vector_trigger 
BEFORE INSERT OR UPDATE ON schedules
FOR EACH ROW EXECUTE FUNCTION update_schedule_search_vector();

-- ============================================
-- FUNCIONES HELPER
-- ============================================

-- Función para detectar conflictos de horario
CREATE OR REPLACE FUNCTION check_schedule_conflict(
    p_session_id1 INTEGER,
    p_session_id2 INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_date1 DATE;
    v_start1 TIME;
    v_end1 TIME;
    v_date2 DATE;
    v_start2 TIME;
    v_end2 TIME;
BEGIN
    SELECT session_date, start_time, end_time 
    INTO v_date1, v_start1, v_end1
    FROM schedules WHERE id = p_session_id1;
    
    SELECT session_date, start_time, end_time 
    INTO v_date2, v_start2, v_end2
    FROM schedules WHERE id = p_session_id2;
    
    -- Solo hay conflicto si son el mismo día Y se solapan los horarios
    RETURN v_date1 = v_date2 AND 
           v_start1 < v_end2 AND 
           v_end1 > v_start2;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener sesiones sin conflictos
CREATE OR REPLACE FUNCTION get_available_sessions(
    p_selected_session_ids INTEGER[]
) RETURNS TABLE(
    session_id INTEGER,
    session_name VARCHAR,
    start_time TIME,
    end_time TIME,
    room_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.session_name,
        s.start_time,
        s.end_time,
        r.room_name
    FROM schedules s
    LEFT JOIN rooms r ON s.room_id = r.id
    WHERE NOT EXISTS (
        SELECT 1 
        FROM unnest(p_selected_session_ids) AS selected_id
        WHERE check_schedule_conflict(s.id, selected_id)
    )
    ORDER BY s.session_date, s.start_time;
END;
$$ LANGUAGE plpgsql;
