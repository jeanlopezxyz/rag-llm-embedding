-- Datos de prueba opcionales
-- ============================================
-- DATOS DE PRUEBA PARA SISTEMA SIMPLIFICADO
-- Un solo evento con múltiples sesiones
-- ============================================

-- Insertar el evento principal
INSERT INTO events (
    event_name, event_date, start_date, end_date, description, 
    location, venue_name, venue_address, max_attendees, website_url
) VALUES (
    'Tech Conference LATAM 2025',
    '2025-03-15',
    '2025-03-15',
    '2025-03-17',
    'La conferencia de tecnología más importante de Latinoamérica. Tres días de charlas, talleres y networking con expertos internacionales en desarrollo de software, data science, DevOps y más.',
    'Lima, Perú',
    'Centro de Convenciones de Lima',
    'Av. Arqueología 206, San Borja, Lima',
    2000,
    'https://techconf-latam.com'
);

-- Insertar Tags
INSERT INTO tags (tag_name, tag_description) VALUES
('Python', 'Lenguaje de programación versátil usado en data science, web y automatización'),
('JavaScript', 'Lenguaje para desarrollo web frontend y backend'),
('Machine Learning', 'Algoritmos y técnicas para que las máquinas aprendan de datos'),
('Data Science', 'Ciencia de extraer conocimiento e insights de los datos'),
('DevOps', 'Prácticas que unen desarrollo y operaciones'),
('Docker', 'Plataforma de contenedores para aplicaciones'),
('Kubernetes', 'Orquestación de contenedores a escala'),
('Cloud Computing', 'Computación en la nube y servicios cloud'),
('React', 'Biblioteca JavaScript para construir interfaces de usuario'),
('Node.js', 'Entorno de ejecución JavaScript del lado del servidor'),
('Microservices', 'Arquitectura de aplicaciones como servicios pequeños e independientes'),
('API REST', 'Diseño de APIs siguiendo principios REST'),
('GraphQL', 'Lenguaje de consulta para APIs'),
('TensorFlow', 'Framework de machine learning de Google'),
('PostgreSQL', 'Base de datos relacional avanzada'),
('MongoDB', 'Base de datos NoSQL orientada a documentos'),
('AWS', 'Amazon Web Services - plataforma cloud'),
('Git', 'Sistema de control de versiones distribuido'),
('Agile', 'Metodologías ágiles de desarrollo'),
('Security', 'Seguridad informática y mejores prácticas');

-- Insertar Tracks
INSERT INTO tracks (track_name, track_description, color_hex, display_order) VALUES
('Data & AI', 'Data Science, Machine Learning e Inteligencia Artificial', '#FF6B6B', 1),
('Web Development', 'Frontend, Backend y Full Stack Development', '#4ECDC4', 2),
('DevOps & Cloud', 'DevOps, Cloud Computing e Infraestructura', '#45B7D1', 3),
('Mobile & IoT', 'Desarrollo móvil e Internet de las Cosas', '#96CEB4', 4),
('Architecture & Design', 'Arquitectura de software y patrones de diseño', '#FECA57', 5);

-- Insertar Venues
INSERT INTO venues (venue_name, venue_type, capacity, floor, amenities, accessibility_features) VALUES
('Auditorio Principal', 'auditorio', 800, 'Planta Baja', 
 ARRAY['proyector 4K', 'sistema de sonido', 'streaming', 'grabación'], 
 ARRAY['rampa', 'elevador', 'baños adaptados']),
('Sala de Conferencias A', 'sala', 200, 'Primer Piso', 
 ARRAY['proyector', 'pizarra digital', 'videoconferencia'], 
 ARRAY['elevador', 'baños adaptados']),
('Sala de Conferencias B', 'sala', 200, 'Primer Piso', 
 ARRAY['proyector', 'pizarra digital', 'videoconferencia'], 
 ARRAY['elevador', 'baños adaptados']),
('Laboratorio de Cómputo 1', 'laboratorio', 50, 'Segundo Piso', 
 ARRAY['30 computadoras', 'proyector', 'pizarra'], 
 ARRAY['elevador']),
('Laboratorio de Cómputo 2', 'laboratorio', 50, 'Segundo Piso', 
 ARRAY['30 computadoras', 'proyector', 'pizarra'], 
 ARRAY['elevador']),
('Área de Networking', 'área común', 300, 'Planta Baja', 
 ARRAY['mesas altas', 'coffee station'], 
 ARRAY['rampa', 'baños adaptados']);

-- Insertar Rooms
INSERT INTO rooms (venue_id, room_code, room_name, capacity, setup_style, equipment) VALUES
(1, 'AUD-MAIN', 'Auditorio Principal', 800, 'teatro', ARRAY['micrófono inalámbrico', 'podium', 'pantalla LED']),
(2, 'CONF-A1', 'Sala Conferencias A1', 200, 'aula', ARRAY['micrófono', 'puntero láser']),
(3, 'CONF-B1', 'Sala Conferencias B1', 200, 'aula', ARRAY['micrófono', 'puntero láser']),
(4, 'LAB-101', 'Laboratorio 101', 50, 'aula', ARRAY['computadoras', 'software instalado']),
(5, 'LAB-102', 'Laboratorio 102', 50, 'aula', ARRAY['computadoras', 'software instalado']),
(6, 'NET-AREA', 'Área de Networking', 300, 'cocktail', ARRAY['mesas altas', 'sistema de sonido ambiental']);

-- Insertar Speakers
INSERT INTO speakers (name, bio, title, company, expertise_areas, is_keynote) VALUES
-- Keynote Speakers
('Dr. Andrew Ng', 'Pionero en IA y fundador de DeepLearning.AI. Ex-director de Google Brain y cofundador de Coursera.', 
 'Founder & CEO', 'DeepLearning.AI', 
 ARRAY['machine learning', 'deep learning', 'artificial intelligence'], true),

('Sarah Drasner', 'VP of Developer Experience en Netlify. Experta en Vue.js, animaciones web y SVG.', 
 'VP Developer Experience', 'Netlify', 
 ARRAY['javascript', 'vue.js', 'web animations', 'developer experience'], true),

-- Regular Speakers
('Carlos Azaustre', 'Google Developer Expert en Web Technologies. Creador de contenido y formador.', 
 'Senior Frontend Engineer', 'Google', 
 ARRAY['javascript', 'react', 'node.js', 'web development'], false),

('Marina Mosti', 'DevRel Engineer y educadora. Especialista en React y desarrollo frontend moderno.', 
 'Developer Relations', 'Platzi', 
 ARRAY['react', 'javascript', 'frontend', 'education'], false),

('Héctor Vega', 'Data Scientist con 10+ años de experiencia en ML y análisis predictivo.', 
 'Lead Data Scientist', 'Mercado Libre', 
 ARRAY['python', 'machine learning', 'data science', 'statistics'], false),

('Ana Belén Valverde', 'Site Reliability Engineer especializada en Kubernetes y cloud native.', 
 'Senior SRE', 'Globant', 
 ARRAY['kubernetes', 'docker', 'devops', 'cloud native'], false),

('Roberto Díaz', 'Arquitecto de Software con expertise en microservicios y sistemas distribuidos.', 
 'Principal Architect', 'BBVA', 
 ARRAY['microservices', 'architecture', 'java', 'distributed systems'], false),

('Laura Sánchez', 'Mobile Developer especializada en desarrollo nativo y Flutter.', 
 'Senior Mobile Developer', 'Rappi', 
 ARRAY['flutter', 'ios', 'android', 'mobile development'], false),

('Miguel Ángel Durán', 'Creador de midudev. Divulgador y desarrollador full stack.', 
 'Principal Engineer', 'Adevinta', 
 ARRAY['javascript', 'react', 'node.js', 'content creation'], false),

('Daniela Rodríguez', 'Security Engineer enfocada en DevSecOps y seguridad en la nube.', 
 'Security Architect', 'Banco Santander', 
 ARRAY['security', 'devsecops', 'cloud security', 'pentesting'], false);

-- Insertar Sponsors
INSERT INTO sponsors (name, logo_url, website_url, sponsor_level, description) VALUES
('Google Cloud', 'https://example.com/google-cloud-logo.png', 'https://cloud.google.com', 'platinum', 
 'Plataforma líder de servicios cloud con soluciones de IA y ML'),
('Microsoft', 'https://example.com/microsoft-logo.png', 'https://microsoft.com', 'platinum', 
 'Tecnología empresarial y servicios cloud Azure'),
('AWS', 'https://example.com/aws-logo.png', 'https://aws.amazon.com', 'gold', 
 'Servicios de computación en la nube de Amazon'),
('GitHub', 'https://example.com/github-logo.png', 'https://github.com', 'gold', 
 'Plataforma de desarrollo colaborativo'),
('JetBrains', 'https://example.com/jetbrains-logo.png', 'https://jetbrains.com', 'silver', 
 'Herramientas de desarrollo profesional'),
('DigitalOcean', 'https://example.com/do-logo.png', 'https://digitalocean.com', 'silver', 
 'Infraestructura cloud para desarrolladores');

-- ============================================
-- INSERTAR SESIONES (SCHEDULES)
-- ============================================

-- DÍA 1: 15 de Marzo 2025

-- Keynotes
INSERT INTO schedules (
    event_id, session_code, session_name, session_description,
    session_type, session_format, difficulty_level, language,
    session_date, start_time, end_time,
    room_id, track_id, max_attendees, requires_registration
) VALUES
-- Opening Keynote
(1, 'KEY-001', 'Apertura: El Futuro de la IA en América Latina',
 'Exploraremos las oportunidades y desafíos únicos que enfrenta América Latina en la adopción de IA, desde la democratización del acceso hasta la creación de soluciones locales para problemas regionales.',
 'keynote', 'presencial', 'todos', 'español',
 '2025-03-15', '09:00', '10:00',
 1, 1, 800, false),

-- Charlas de la mañana
(1, 'TALK-001', 'Introducción a Machine Learning con Python',
 'Aprende los conceptos fundamentales de ML y cómo implementar tus primeros modelos con scikit-learn. Cubriremos clasificación, regresión y clustering con ejemplos prácticos.',
 'charla', 'presencial', 'básico', 'español',
 '2025-03-15', '10:30', '11:30',
 2, 1, 200, false),

(1, 'TALK-002', 'React 19: Novedades y Mejores Prácticas',
 'Descubre las nuevas características de React 19, incluyendo Server Components, mejoras en rendimiento y las nuevas APIs. Veremos ejemplos prácticos de migración.',
 'charla', 'presencial', 'intermedio', 'español',
 '2025-03-15', '10:30', '11:30',
 3, 2, 200, false),

(1, 'WS-001', 'Taller: Docker desde Cero',
 'Taller práctico donde aprenderás a containerizar aplicaciones, crear Dockerfiles eficientes y gestionar imágenes. Traer laptop con Docker instalado.',
 'taller', 'presencial', 'básico', 'español',
 '2025-03-15', '10:30', '12:30',
 4, 3, 50, true),

-- Charlas antes del almuerzo
(1, 'TALK-003', 'Arquitectura de Microservicios: Casos Reales',
 'Compartiremos experiencias reales implementando microservicios en producción. Patrones, anti-patrones y lecciones aprendidas en empresas latinoamericanas.',
 'charla', 'presencial', 'avanzado', 'español',
 '2025-03-15', '11:45', '12:45',
 2, 5, 200, false),

(1, 'TALK-004', 'Vue 3 Composition API en Proyectos Grandes',
 'Estrategias para escalar aplicaciones Vue 3 usando Composition API. Organización de código, testing y performance en aplicaciones empresariales.',
 'charla', 'presencial', 'intermedio', 'español',
 '2025-03-15', '11:45', '12:45',
 3, 2, 200, false),

-- Almuerzo y Networking
(1, 'NET-001', 'Almuerzo y Networking',
 'Espacio para networking, conocer otros profesionales y compartir experiencias mientras disfrutas del almuerzo.',
 'networking', 'presencial', 'todos', 'español',
 '2025-03-15', '13:00', '14:30',
 6, NULL, 300, false),

-- Charlas de la tarde
(1, 'TALK-005', 'Deep Learning para Computer Vision',
 'Introducción práctica a redes neuronales convolucionales con TensorFlow/Keras. Construiremos un clasificador de imágenes desde cero.',
 'charla', 'presencial', 'intermedio', 'español',
 '2025-03-15', '14:30', '15:30',
 2, 1, 200, false),

(1, 'TALK-006', 'GraphQL vs REST: Cuándo usar cada uno',
 'Análisis comparativo de GraphQL y REST. Ventajas, desventajas y criterios para elegir la mejor opción según tu proyecto.',
 'charla', 'presencial', 'intermedio', 'español',
 '2025-03-15', '14:30', '15:30',
 3, 2, 200, false),

(1, 'WS-002', 'Taller: Kubernetes para Desarrolladores',
 'Aprende a desplegar aplicaciones en Kubernetes. Pods, Services, Deployments e Ingress. Requisito: conocimientos básicos de Docker.',
 'taller', 'presencial', 'intermedio', 'español',
 '2025-03-15', '14:30', '17:30',
 5, 3, 50, true),

-- Panel de discusión
(1, 'PANEL-001', 'Panel: El Estado del Desarrollo de Software en LATAM',
 'Líderes de la industria discuten tendencias, oportunidades y desafíos del desarrollo de software en América Latina.',
 'panel', 'presencial', 'todos', 'español',
 '2025-03-15', '16:00', '17:00',
 1, NULL, 800, false),

-- Cierre del día
(1, 'NET-002', 'Happy Hour de Networking',
 'Cierre del primer día con bebidas y snacks. Oportunidad perfecta para continuar las conversaciones del día.',
 'networking', 'presencial', 'todos', 'español',
 '2025-03-15', '17:30', '19:00',
 6, NULL, 300, false),

-- DÍA 2: 16 de Marzo 2025

-- Keynote del día 2
(1, 'KEY-002', 'JavaScript: El Presente y Futuro del Desarrollo Web',
 'Un recorrido por el ecosistema JavaScript moderno, desde los frameworks actuales hasta las propuestas futuras del lenguaje.',
 'keynote', 'presencial', 'todos', 'inglés',
 '2025-03-16', '09:00', '10:00',
 1, 2, 800, false),

-- Sesiones de la mañana
(1, 'TALK-007', 'Data Engineering con Apache Spark',
 'Procesamiento de datos a gran escala con Spark. ETL pipelines, optimización y mejores prácticas para big data.',
 'charla', 'presencial', 'avanzado', 'español',
 '2025-03-16', '10:30', '11:30',
 2, 1, 200, false),

(1, 'TALK-008', 'Flutter: Desarrollo Multiplataforma Eficiente',
 'Crea aplicaciones nativas para iOS y Android con un solo código base. Widgets, estado y arquitectura en Flutter.',
 'charla', 'presencial', 'intermedio', 'español',
 '2025-03-16', '10:30', '11:30',
 3, 4, 200, false),

(1, 'WS-003', 'Taller: CI/CD con GitHub Actions',
 'Implementa pipelines de CI/CD profesionales. Automatización de tests, builds y deployments con GitHub Actions.',
 'taller', 'presencial', 'intermedio', 'español',
 '2025-03-16', '10:30', '12:30',
 4, 3, 50, true),

(1, 'TALK-009', 'Seguridad en APIs REST',
 'Mejores prácticas de seguridad para APIs: autenticación, autorización, rate limiting y prevención de ataques comunes.',
 'charla', 'presencial', 'intermedio', 'español',
 '2025-03-16', '11:45', '12:45',
 2, 5, 200, false),

(1, 'TALK-010', 'Node.js Performance Optimization',
 'Técnicas avanzadas para optimizar aplicaciones Node.js. Profiling, caching, clustering y manejo eficiente de memoria.',
 'charla', 'híbrido', 'avanzado', 'español',
 '2025-03-16', '11:45', '12:45',
 3, 2, 200, false),

-- Tarde del día 2
(1, 'TALK-011', 'MLOps: Machine Learning en Producción',
 'El ciclo de vida completo de modelos ML en producción. Versionado, monitoreo, A/B testing y actualización continua.',
 'charla', 'presencial', 'avanzado', 'español',
 '2025-03-16', '14:30', '15:30',
 2, 1, 200, false),

(1, 'TALK-012', 'Microfrontends con Module Federation',
 'Arquitectura de microfrontends usando Webpack Module Federation. Casos de uso, implementación y desafíos.',
 'charla', 'presencial', 'avanzado', 'español',
 '2025-03-16', '14:30', '15:30',
 3, 2, 200, false),

(1, 'WS-004', 'Taller: Testing E2E con Cypress',
 'Testing end-to-end moderno con Cypress. Escribir tests mantenibles, debugging y mejores prácticas.',
 'taller', 'presencial', 'intermedio', 'español',
 '2025-03-16', '14:30', '16:30',
 4, 2, 50, true),

-- DÍA 3: 17 de Marzo 2025

-- Última jornada
(1, 'TALK-013', 'Construyendo un Data Lake en AWS',
 'Arquitectura completa de un data lake usando servicios AWS: S3, Glue, Athena y QuickSight.',
 'charla', 'presencial', 'avanzado', 'español',
 '2025-03-17', '09:00', '10:00',
 2, 1, 200, false),

(1, 'TALK-014', 'WebAssembly: El Futuro de la Web',
 'Introducción a WebAssembly y cómo puede revolucionar el desarrollo web. Casos de uso y ejemplos prácticos.',
 'charla', 'virtual', 'intermedio', 'español',
 '2025-03-17', '09:00', '10:00',
 3, 2, 200, false),

(1, 'WS-005', 'Taller: Introducción a Rust',
 'Primeros pasos con Rust. Ownership, borrowing y por qué Rust es el lenguaje más amado por desarrolladores.',
 'taller', 'presencial', 'básico', 'español',
 '2025-03-17', '10:30', '12:30',
 5, 5, 50, true),

-- Keynote de cierre
(1, 'KEY-003', 'Cerrando la Brecha: Tecnología para el Impacto Social',
 'Cómo la tecnología puede resolver problemas sociales en América Latina. Casos de éxito y oportunidades futuras.',
 'keynote', 'presencial', 'todos', 'español',
 '2025-03-17', '13:00', '14:00',
 1, NULL, 800, false);

-- ============================================
-- RELACIONES: SESSION_SPEAKERS
-- ============================================

INSERT INTO session_speakers (session_id, speaker_id, role, is_primary, speaker_order) VALUES
-- Keynotes
(1, 1, 'speaker', true, 1),  -- Andrew Ng en apertura
(13, 2, 'speaker', true, 1), -- Sarah Drasner en JS keynote
(25, 1, 'speaker', true, 1), -- Andrew Ng en cierre (podría ser otro speaker)

-- Charlas regulares
(2, 5, 'speaker', true, 1),  -- Héctor Vega - ML con Python
(3, 4, 'speaker', true, 1),  -- Marina Mosti - React 19
(4, 6, 'speaker', true, 1),  -- Ana Belén - Docker
(5, 7, 'speaker', true, 1),  -- Roberto Díaz - Microservicios
(6, 3, 'speaker', true, 1),  -- Carlos Azaustre - Vue 3
(8, 5, 'speaker', true, 1),  -- Héctor Vega - Deep Learning
(9, 9, 'speaker', true, 1),  -- Miguel Ángel - GraphQL vs REST
(10, 6, 'speaker', true, 1), -- Ana Belén - Kubernetes

-- Panel (múltiples speakers)
(11, 2, 'panelist', false, 1),
(11, 3, 'panelist', false, 2),
(11, 7, 'panelist', false, 3),
(11, 9, 'moderator', true, 4),

-- Día 2
(14, 5, 'speaker', true, 1),  -- Data Engineering
(15, 8, 'speaker', true, 1),  -- Flutter
(16, 6, 'speaker', true, 1),  -- CI/CD
(17, 10, 'speaker', true, 1), -- Seguridad APIs
(18, 3, 'speaker', true, 1),  -- Node.js Performance
(19, 5, 'speaker', true, 1),  -- MLOps
(20, 9, 'speaker', true, 1),  -- Microfrontends
(21, 4, 'speaker', true, 1),  -- Testing con Cypress

-- Día 3
(22, 5, 'speaker', true, 1),  -- Data Lake AWS
(23, 3, 'speaker', true, 1),  -- WebAssembly
(24, 7, 'speaker', true, 1);  -- Rust

-- ============================================
-- RELACIONES: SESSION_TAGS
-- ============================================

INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES
-- Keynote IA
(1, 3, 1.0), (1, 4, 0.9),

-- ML con Python
(2, 1, 1.0), (2, 3, 1.0), (2, 4, 0.8),

-- React 19
(3, 2, 1.0), (3, 9, 1.0),

-- Docker
(4, 6, 1.0), (4, 5, 0.8),

-- Microservicios
(5, 11, 1.0), (5, 12, 0.8), (5, 19, 0.7),

-- Vue 3
(6, 2, 1.0), (6, 9, 0.9),

-- Deep Learning
(8, 3, 1.0), (8, 14, 1.0), (8, 1, 0.8),

-- GraphQL vs REST
(9, 12, 1.0), (9, 13, 1.0),

-- Kubernetes
(10, 7, 1.0), (10, 5, 0.9), (10, 8, 0.8),

-- Data Engineering Spark
(14, 4, 1.0), (14, 1, 0.8), (14, 8, 0.7),

-- Flutter
(15, 10, 0.7),

-- CI/CD
(16, 5, 1.0), (16, 18, 0.9),

-- Seguridad APIs
(17, 20, 1.0), (17, 12, 0.8),

-- Node.js
(18, 2, 1.0), (18, 10, 1.0),

-- MLOps
(19, 3, 1.0), (19, 5, 1.0), (19, 4, 0.9),

-- Microfrontends
(20, 2, 1.0), (20, 11, 0.9),

-- Testing Cypress
(21, 2, 1.0), (21, 19, 0.8),

-- Data Lake
(22, 4, 1.0), (22, 17, 1.0), (22, 8, 0.9),

-- WebAssembly
(23, 2, 0.8),

-- Rust
(24, 19, 0.7);

-- ============================================
-- RECURSOS DE SESIONES (algunos ejemplos)
-- ============================================

INSERT INTO session_resources (session_id, resource_type, resource_name, resource_url, resource_description) VALUES
(2, 'slides', 'Introducción a ML - Slides', 'https://slides.com/ml-intro', 'Presentación completa del taller'),
(2, 'código', 'Notebooks de ejemplos', 'https://github.com/conf/ml-notebooks', 'Jupyter notebooks con los ejercicios'),
(3, 'slides', 'React 19 Novedades', 'https://slides.com/react-19', 'Slides de la presentación'),
(4, 'código', 'Docker Workshop Files', 'https://github.com/conf/docker-workshop', 'Archivos necesarios para el taller'),
(10, 'código', 'Kubernetes Manifests', 'https://github.com/conf/k8s-workshop', 'Archivos YAML para el taller');
