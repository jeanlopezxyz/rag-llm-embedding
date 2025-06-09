
-- EVENT

INSERT INTO events (id, event_name, event_date, start_date, end_date, description, location, venue_name, venue_address, max_attendees, website_url)
VALUES (1, 'KCD Antigua Guatemala 2025', '2025-06-14', '2025-06-14', '2025-06-14', 
'Evento de la comunidad Kubernetes en Guatemala con charlas sobre CI/CD, seguridad, IA, GitOps y más.', 
'Antigua Guatemala', 'Centro de Convenciones Antigua', 'Antigua Guatemala, Guatemala', 
500, 'https://community.cncf.io/kcd-guatemala/');


-- VENUES
INSERT INTO venues (id, venue_name, venue_type, capacity) VALUES (1, 'Landívar', 'auditorio', 200);
INSERT INTO venues (id, venue_name, venue_type, capacity) VALUES (2, 'El Obispo', 'auditorio', 200);
INSERT INTO venues (id, venue_name, venue_type, capacity) VALUES (3, 'Don Pedro', 'auditorio', 200);

-- ROOMS
INSERT INTO rooms (id, venue_id, room_code, room_name, capacity, setup_style) VALUES (1, 1, 'ROOM-1', 'Salón Landívar', 200, 'auditorio');
INSERT INTO rooms (id, venue_id, room_code, room_name, capacity, setup_style) VALUES (2, 2, 'ROOM-2', 'Salón El Obispo', 200, 'auditorio');
INSERT INTO rooms (id, venue_id, room_code, room_name, capacity, setup_style) VALUES (3, 3, 'ROOM-3', 'Salón Don Pedro', 200, 'auditorio');

-- SPEAKERS
INSERT INTO speakers (id, name, company, email) VALUES (1, 'Sergio Méndez', 'USAC', 'sergio.mendez@usac.edu.gt');
INSERT INTO speakers (id, name, company, email) VALUES (2, 'Alvin Estrada', 'Walmart', 'alvin.estrada@walmart.com');
INSERT INTO speakers (id, name, company, email) VALUES (3, 'Jorge Andrade', 'ITM', 'jorge.andrade@itm.com');
INSERT INTO speakers (id, name, company, email) VALUES (4, 'Victor Castellanos', 'InfoUtility GT', 'victor.castellanos@infoutility.com');
INSERT INTO speakers (id, name, company, email) VALUES (5, 'Scott Rigby', 'Replicated', 'scott.rigby@replicated.com');
INSERT INTO speakers (id, name, company, email) VALUES (6, 'Victor Pinzon', 'Bantrab', 'victor.pinzon@bantrab.com');
INSERT INTO speakers (id, name, company, email) VALUES (7, 'Eduardo Spotti', 'Crubyt', 'eduardo.spotti@crubyt.io');
INSERT INTO speakers (id, name, company, email) VALUES (8, 'Jean Paul López', 'Red Hat', 'jeanpaul.lopez@redhat.com');
INSERT INTO speakers (id, name, company, email) VALUES (9, 'Jorge Romero', 'BDG / EDUKIDS', 'jorge.romero@edukids.org');
INSERT INTO speakers (id, name, company, email) VALUES (10, 'Jackeline Benitez', 'Telus Digital', 'jackeline.benitez@telus.com');
INSERT INTO speakers (id, name, company, email) VALUES (11, 'Adalberto García', 'BYTE', 'adalberto.garcia@byte.gt');
INSERT INTO speakers (id, name, company, email) VALUES (12, 'Edwin Chuy', 'Distribuidora Mariscal', 'edwin.chuy@mariscal.com');
INSERT INTO speakers (id, name, company, email) VALUES (13, 'Fabrizio Sgura', 'Veritas Automata', 'fabrizio.sgura@veritasautomata.io');
INSERT INTO speakers (id, name, company, email) VALUES (14, 'Areli Solis', 'Concert', 'areli.solis@concert.io');
INSERT INTO speakers (id, name, company, email) VALUES (15, 'Cami Martins', 'Storyblok', 'cami.martins@storyblok.com');
INSERT INTO speakers (id, name, company, email) VALUES (16, 'Jorge De León', 'Martinxsa', 'jorge.deleon@martinxsa.com');
INSERT INTO speakers (id, name, company, email) VALUES (17, 'Hugo Guerrero', 'Kong Inc.', 'hugo.guerrero@konghq.com');
INSERT INTO speakers (id, name, company, email) VALUES (18, 'Jesús Aguirre', 'Indra', 'jesus.aguirre@indra.com');
INSERT INTO speakers (id, name, company, email) VALUES (19, 'Alejandro Lembke', 'P-lao | Telus Digital', 'alejandro.lembke@telus.com');
INSERT INTO speakers (id, name, company, email) VALUES (20, 'Carlos Martinez', 'Freelance', 'carlos.martinez@gmail.com');
INSERT INTO speakers (id, name, company, email) VALUES (21, 'Alejandro Mercado', 'KMMX', 'alejandro.mercado@kmmx.mx');
INSERT INTO speakers (id, name, company, email) VALUES (22, 'José Reynoso', 'Freelance', 'jose.reynoso@gmail.com');
INSERT INTO speakers (id, name, company, email) VALUES (23, 'Stephanie Hohenberg', 'IT Consultant', 'stephanie.hohenberg@consultant.io');
INSERT INTO speakers (id, name, company, email) VALUES (24, 'Andres Arroyo', 'GBM', 'andres.arroyo@gbm.net');
INSERT INTO speakers (id, name, company, email) VALUES (25, 'Johan Prieto', 'CursaCloud', 'johan.prieto@cursacloud.io');
INSERT INTO speakers (id, name, company, email) VALUES (26, 'Bayron Carranza', '3Pillar', 'bayron.carranza@3pillarglobal.com');


-- SCHEDULES

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (1, 1, 'Tecnologías Cloud Native en Guatemala + Future de nube', 'charla', '2025-06-14', '09:00:00', '09:05:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (2, 1, 'ARM - Sponsored', 'sponsored', '2025-06-14', '09:05:00', '09:20:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (3, 1, 'Telus International - Sponsored', 'sponsored', '2025-06-14', '09:20:00', '09:30:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (4, 1, 'Utilizando Backstage para ambientes de pruebas - Sponsored', 'sponsored', '2025-06-14', '09:30:00', '09:45:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (5, 1, 'Domina Kubernetes con HELM', 'charla', '2025-06-14', '11:00:00', '11:35:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (6, 1, 'Expanding the Helm Ecosystem With Helm 4', 'charla', '2025-06-14', '11:35:00', '12:10:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (7, 1, 'Kubernetes Autoscaling: Scaling Your Applications Based on Events with KEDA', 'charla', '2025-06-14', '13:20:00', '13:55:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (8, 1, 'Kubernetes security incident response', 'charla', '2025-06-14', '15:05:00', '15:40:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (9, 1, 'Construyendo un Chatbot con Kubeflow, LangChain y DeepSeek', 'charla', '2025-06-14', '15:40:00', '16:15:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (10, 1, 'Tecnología que ve por ti: IA, visión computacional y Kubernetes en el borde', 'charla', '2025-06-14', '16:15:00', '16:50:00', 1);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (11, 1, 'La importancia del CI/CD y cómo implementarlo', 'workshop', '2025-06-14', '09:40:00', '10:30:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (12, 1, 'El dilema entre estabilidad y rendimiento en Kubernetes', 'charla', '2025-06-14', '10:30:00', '11:00:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (13, 1, 'El Rol de AKS con Databricks para Implementación de MLOps a Escala', 'charla', '2025-06-14', '11:00:00', '11:30:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (14, 1, 'De Harbor a Kubernetes: Un Recorrido Guiado por GitOps para CI/CD Seguro', 'charla', '2025-06-14', '11:30:00', '12:10:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (15, 1, 'Kubernetes Blindado: Seguridad y el Cumplimiento en la Era de los Contenedores', 'charla', '2025-06-14', '13:20:00', '13:55:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (16, 1, 'eBPF y insights con Gemini', 'charla', '2025-06-14', '14:30:00', '15:05:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (17, 1, 'Contenerización y Kubernetes 101', 'charla', '2025-06-14', '15:05:00', '15:40:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (18, 1, 'Simplifica la gestión de eventos en tus aplicaciones con Knative Eventing', 'charla', '2025-06-14', '15:40:00', '16:15:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (19, 1, 'Cloud Native: Sus Prácticas, Escalabilidad y Comunidad', 'charla', '2025-06-14', '16:15:00', '16:50:00', 2);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (20, 1, 'KubeVirt: La nueva virtualización', 'charla', '2025-06-14', '14:30:00', '15:05:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (21, 1, 'GitOps: La verdad está en el repositorio', 'charla', '2025-06-14', '10:30:00', '11:00:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (22, 1, 'Kubernetes en el Diamante: Plataforma Deportiva Cloud Native en Guatemala', 'charla', '2025-06-14', '15:05:00', '15:40:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (23, 1, 'Protegiendo mis APIs con Auth0 + OAuth2 Proxy en Kubernetes', 'charla', '2025-06-14', '15:40:00', '16:15:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (24, 1, 'Streamlining Kubernetes Provisioning with kOps and Infra-as-Code', 'charla', '2025-06-14', '16:15:00', '16:50:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (25, 1, 'Automatización con ArgoCD y herramientas GitOps', 'charla', '2025-06-14', '09:40:00', '10:30:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (26, 1, 'Microservicios con Dapr y Kubernetes', 'charla', '2025-06-14', '11:00:00', '11:35:00', 3);

INSERT INTO schedules (id, event_id, session_name, session_type, session_date, start_time, end_time, room_id)
VALUES (27, 1, 'Backend para Juegos con Kubernetes y Redis', 'charla', '2025-06-14', '11:35:00', '12:10:00', 3);


-- SESSION SPEAKERS

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (1, 1, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (1, 2, False, 1);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (4, 3, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (5, 4, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (6, 5, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (7, 6, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (8, 7, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (9, 8, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (10, 9, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (11, 10, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (12, 11, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (13, 12, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (14, 13, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (15, 14, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (16, 15, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (17, 16, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (18, 17, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (19, 18, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (20, 19, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (21, 20, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (22, 21, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (23, 22, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (24, 23, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (25, 24, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (26, 25, True, 0);

INSERT INTO session_speakers (session_id, speaker_id, is_primary, speaker_order)
VALUES (27, 26, True, 0);


-- TAGS
INSERT INTO tags (id, tag_name, tag_description) VALUES (1, 'Kubernetes', 'Orquestación de contenedores');
INSERT INTO tags (id, tag_name, tag_description) VALUES (2, 'GitOps', 'Implementación continua basada en Git');
INSERT INTO tags (id, tag_name, tag_description) VALUES (3, 'IA', 'Inteligencia artificial aplicada');
INSERT INTO tags (id, tag_name, tag_description) VALUES (4, 'CI/CD', 'Integración y entrega continua');
INSERT INTO tags (id, tag_name, tag_description) VALUES (5, 'Seguridad', 'Buenas prácticas de seguridad en la nube');
INSERT INTO tags (id, tag_name, tag_description) VALUES (6, 'eBPF', 'Extended Berkeley Packet Filter');
INSERT INTO tags (id, tag_name, tag_description) VALUES (7, 'Backstage', 'Plataforma de desarrollo interno');
INSERT INTO tags (id, tag_name, tag_description) VALUES (8, 'KEDA', 'Escalado basado en eventos para Kubernetes');
INSERT INTO tags (id, tag_name, tag_description) VALUES (9, 'Knative', 'Serverless para Kubernetes');
INSERT INTO tags (id, tag_name, tag_description) VALUES (10, 'OAuth2', 'Autenticación y autorización segura');
INSERT INTO tags (id, tag_name, tag_description) VALUES (11, 'ArgoCD', 'Herramienta GitOps para Kubernetes');
INSERT INTO tags (id, tag_name, tag_description) VALUES (12, 'Redis', 'Base de datos en memoria para alta velocidad');
INSERT INTO tags (id, tag_name, tag_description) VALUES (13, 'KubeVirt', 'Virtualización de VMs en Kubernetes');
INSERT INTO tags (id, tag_name, tag_description) VALUES (14, 'MLOps', 'Machine Learning en producción');
INSERT INTO tags (id, tag_name, tag_description) VALUES (15, 'Dapr', 'Runtime para microservicios');

-- TRACKS
INSERT INTO tracks (id, track_name, track_description, color_hex, display_order) VALUES (1, 'Cloud Native', 'Todo sobre tecnologías cloud-native', '#4287f5', 1);
INSERT INTO tracks (id, track_name, track_description, color_hex, display_order) VALUES (2, 'Security', 'Seguridad y cumplimiento', '#f54242', 2);
INSERT INTO tracks (id, track_name, track_description, color_hex, display_order) VALUES (3, 'Data & AI', 'Inteligencia Artificial y Machine Learning', '#42f554', 3);
INSERT INTO tracks (id, track_name, track_description, color_hex, display_order) VALUES (4, 'Developer Experience', 'Herramientas para desarrolladores', '#f5a142', 4);
INSERT INTO tracks (id, track_name, track_description, color_hex, display_order) VALUES (5, 'GitOps & CI/CD', 'Automatización del ciclo de vida', '#9b42f5', 5);

-- SESSION TAGS
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (1, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (1, 5, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (4, 7, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (5, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (5, 11, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (6, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (7, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (7, 8, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (8, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (8, 5, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (9, 3, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (10, 3, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (10, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (11, 4, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (12, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (13, 14, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (14, 2, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (14, 11, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (15, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (15, 5, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (16, 6, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (17, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (18, 9, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (19, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (19, 4, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (20, 13, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (21, 2, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (22, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (23, 10, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (24, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (24, 2, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (25, 11, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (26, 15, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (27, 1, 1.0);
INSERT INTO session_tags (session_id, tag_id, relevance_score) VALUES (27, 12, 1.0);

-- SESSION RESOURCES
INSERT INTO session_resources (id, session_id, resource_type, resource_name, resource_url) VALUES (1, 1, 'slides', 'Presentación principal', 'https://kcd.gt/slides/1.pdf');
INSERT INTO session_resources (id, session_id, resource_type, resource_name, resource_url) VALUES (2, 5, 'repository', 'Repo Helm Demo', 'https://github.com/demo/helm');
INSERT INTO session_resources (id, session_id, resource_type, resource_name, resource_url) VALUES (3, 9, 'repository', 'Chatbot Demo', 'https://github.com/demo/chatbot');
INSERT INTO session_resources (id, session_id, resource_type, resource_name, resource_url) VALUES (4, 18, 'slides', 'Knative Eventing PDF', 'https://kcd.gt/slides/knative.pdf');
