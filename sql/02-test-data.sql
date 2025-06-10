/* ============================================================
   KCD Antigua Guatemala 2025 
   Version “lite”  — sin emails, sin social_links, sin session_resources
   Cargar después de 01-schema-source.sql
   ============================================================ */

/*----------------------------------------------------------------
  1) EVENTO
----------------------------------------------------------------*/
INSERT INTO events (id,event_name,event_date,start_date,end_date,description,
                    location,venue_name,venue_address,max_attendees,website_url)
VALUES (1,'KCD Antigua Guatemala 2025','2025-06-14','2025-06-14','2025-06-14',
        'Evento CNCF con charlas de Cloud Native, Seguridad, IA, GitOps y más.',
        'Antigua Guatemala','Centro de Convenciones Antigua',
        'Antigua Guatemala, Guatemala',500,
        'https://community.cncf.io/kcd-guatemala/');

/*----------------------------------------------------------------
  2) TRACKS
----------------------------------------------------------------*/
INSERT INTO tracks (id,track_name,track_description,color_hex,display_order) VALUES
(1,'Cloud Native'         ,'Plataformas y patrones nativos de nube'           ,'#4287F5',1),
(2,'Security'             ,'Seguridad, cumplimiento y observabilidad'        ,'#F54242',2),
(3,'Data & AI'            ,'Machine Learning, MLOps e IA'                    ,'#42F554',3),
(4,'DevOps & Automation'  ,'Infra-as-Code, plataformas, virtualización'      ,'#F5A142',4),
(5,'GitOps & CI/CD'       ,'Entregas continuas declarativas'                 ,'#9B42F5',5),
(6,'Developer Experience' ,'Herramientas para productividad dev'             ,'#8080FF',6);

/*----------------------------------------------------------------
  3) TAGS   (26)
----------------------------------------------------------------*/
INSERT INTO tags (id,tag_name,tag_description) VALUES
( 1,'kubernetes','Orquestación de contenedores'),
( 2,'cloud-native','Patrones nativos de nube'),
( 3,'security','Buenas prácticas de seguridad'),
( 4,'gitops','Git como fuente de la verdad'),
( 5,'cicd','Integración y entrega continua'),
( 6,'devops','Cultura y automatización DevOps'),
( 7,'automation','Infraestructura como código'),
( 8,'ia','Inteligencia artificial'),
( 9,'mlops','ML en producción'),
(10,'serverless','Funcionalidades bajo demanda'),
(11,'backstage','Plataforma de desarrollo interno'),
(12,'helm','Gestión de charts Helm'),
(13,'keda','Escalado basado en eventos'),
(14,'ebpf','eBPF y observabilidad avanzada'),
(15,'oauth2','Autenticación y autorización'),
(16,'argocd','GitOps con Argo CD'),
(17,'redis','Base de datos en memoria'),
(18,'kubevirt','Virtualización de VMs en K8s'),
(19,'dapr','Runtime de microservicios'),
(20,'edge-computing','Computación de borde'),
(21,'chatbot','Chatbots & LLMs'),
(22,'gaming','Plataformas de gaming'),
(23,'observability','Logs, traces, métricas'),
(24,'kops','Provisioning con kOps'),
(25,'service-mesh','Istio / Linkerd'),
(26,'autoscaling','Autoscaling (HPA/KEDA)');

/*----------------------------------------------------------------
  4) VENUES y ROOMS
----------------------------------------------------------------*/
INSERT INTO venues (id,venue_name,venue_type,capacity) VALUES
(1,'Landívar','auditorio',200),
(2,'El Obispo','auditorio',200),
(3,'Don Pedro','auditorio',200);

INSERT INTO rooms (id,venue_id,room_code,room_name,capacity,setup_style) VALUES
(1,1,'ROOM-1','Salón Landívar',200,'auditorio'),
(2,2,'ROOM-2','Salón El Obispo',200,'auditorio'),
(3,3,'ROOM-3','Salón Don Pedro',200,'auditorio');

/*----------------------------------------------------------------
  5) SPEAKERS  (sin correo ni social_links)
----------------------------------------------------------------*/
INSERT INTO speakers (id,name,company) VALUES
( 1,'Sergio Méndez'      ,'USAC'),
( 2,'Alvin Estrada'      ,'Walmart'),
( 3,'Jorge Andrade'      ,'ITM'),
( 4,'Víctor Castellanos' ,'InfoUtility GT'),
( 5,'Scott Rigby'        ,'Replicated'),
( 6,'Víctor Pinzón'      ,'Bantrab'),
( 7,'Eduardo Spotti'     ,'Crubyt'),
( 8,'Jean Paul López'    ,'Red Hat'),
( 9,'Jorge Romero'       ,'BDG / EDUKIDS'),
(10,'Jackeline Benítez'  ,'Telus Digital'),
(11,'Adalberto García'   ,'BYTE'),
(12,'Edwin Chuy'         ,'Distribuidora Mariscal'),
(13,'Fabrizio Sgura'     ,'Veritas Automata'),
(14,'Areli Solis'        ,'Concert'),
(15,'Cami Martins'       ,'Storyblok'),
(16,'Jorge De León'      ,'Martinxsa'),
(17,'Hugo Guerrero'      ,'Kong Inc.'),
(18,'Jesús Aguirre'      ,'Indra'),
(19,'Alejandro Lembke'   ,'P-lao | Telus'),
(20,'Carlos Martínez'    ,'Freelance'),
(21,'Alejandro Mercado'  ,'KMMX'),
(22,'José Reynoso'       ,'Freelance'),
(23,'Stephanie Hohenberg','IT Consultant'),
(24,'Andrés Arroyo'      ,'GBM'),
(25,'Johan Prieto'       ,'CursaCloud'),
(26,'Bayron Carranza'    ,'3Pillar');

/*----------------------------------------------------------------
  6) SCHEDULES  (27 sesiones)   – track_id y URLs
----------------------------------------------------------------*/
INSERT INTO schedules (id,event_id,session_name,session_type,track_id,
                       session_date,start_time,end_time,room_id,
                       slides_url,repository_url)
VALUES
/* --- Landívar --- */
( 1,1,'Tecnologías Cloud Native en Guatemala + Future de nube','charla',1,'2025-06-14','09:00','09:05',1,
  'https://kcd.gt/slides/keynote.pdf',NULL),
( 2,1,'ARM – Sponsored','sponsored',6,'2025-06-14','09:05','09:20',1,NULL,NULL),
( 3,1,'Telus International – Sponsored','sponsored',6,'2025-06-14','09:20','09:30',1,NULL,NULL),
( 4,1,'Utilizando Backstage para ambientes de pruebas','charla',6,'2025-06-14','09:30','09:45',1,
  'https://kcd.gt/slides/backstage.pdf',NULL),
( 5,1,'Domina Kubernetes con HELM','charla',6,'2025-06-14','11:00','11:35',1,
  'https://kcd.gt/slides/helm.pdf','https://github.com/demo/helm'),
( 6,1,'Expanding the Helm Ecosystem With Helm 4','charla',6,'2025-06-14','11:35','12:10',1,
  NULL,'https://github.com/demo/helm4'),
( 7,1,'Kubernetes Autoscaling con KEDA','charla',1,'2025-06-14','13:20','13:55',1,
  'https://kcd.gt/slides/keda.pdf',NULL),
( 8,1,'Kubernetes Security Incident Response','charla',2,'2025-06-14','15:05','15:40',1,
  'https://kcd.gt/slides/security-ir.pdf',NULL),
( 9,1,'Chatbot con Kubeflow, LangChain y DeepSeek','charla',3,'2025-06-14','15:40','16:15',1,
  NULL,'https://github.com/demo/chatbot-kcd'),
(10,1,'IA y Visión Computacional en el Borde','charla',3,'2025-06-14','16:15','16:50',1,
  'https://kcd.gt/slides/edge-ai.pdf',NULL),

/* --- El Obispo --- */
(11,1,'CI/CD End-to-End: de commit a prod','workshop',5,'2025-06-14','09:40','10:30',2,
  'https://kcd.gt/slides/cicd.pdf',NULL),
(12,1,'Estabilidad vs. Rendimiento en Kubernetes','charla',1,'2025-06-14','10:30','11:00',2,NULL,NULL),
(13,1,'AKS+Databricks para MLOps a Escala','charla',3,'2025-06-14','11:00','11:30',2,
  'https://kcd.gt/slides/mlops-aks.pdf',NULL),
(14,1,'De Harbor a Kubernetes: GitOps seguro','charla',5,'2025-06-14','11:30','12:10',2,
  'https://kcd.gt/slides/gitops-secure.pdf','https://github.com/demo/gitops-secure'),
(15,1,'Kubernetes Blindado: Seguridad & Compliance','charla',2,'2025-06-14','13:20','13:55',2,NULL,NULL),
(16,1,'eBPF & Gemini Insights','charla',2,'2025-06-14','14:30','15:05',2,
  'https://kcd.gt/slides/ebpf-gemini.pdf',NULL),
(17,1,'Contenerización y Kubernetes 101','charla',4,'2025-06-14','15:05','15:40',2,NULL,NULL),
(18,1,'Knative Eventing: Simplifica eventos','charla',1,'2025-06-14','15:40','16:15',2,
  'https://kcd.gt/slides/knative.pdf',NULL),
(19,1,'Prácticas Cloud Native y Comunidad','charla',1,'2025-06-14','16:15','16:50',2,NULL,NULL),

/* --- Don Pedro --- */
(20,1,'KubeVirt: La nueva virtualización','charla',4,'2025-06-14','14:30','15:05',3,
  'https://kcd.gt/slides/kubevirt.pdf',NULL),
(21,1,'GitOps: La verdad está en el repo','charla',5,'2025-06-14','10:30','11:00',3,
  'https://kcd.gt/slides/gitops-repo.pdf',NULL),
(22,1,'Plataforma Deportiva Cloud Native','charla',1,'2025-06-14','15:05','15:40',3,NULL,NULL),
(23,1,'Protegiendo APIs con Auth0 + OAuth2','charla',2,'2025-06-14','15:40','16:15',3,
  'https://kcd.gt/slides/oauth2.pdf','https://github.com/demo/oauth2-proxy'),
(24,1,'Provisioning con kOps & IaC','charla',4,'2025-06-14','16:15','16:50',3,
  NULL,'https://github.com/demo/kops-iac'),
(25,1,'Automatización con Argo CD','charla',5,'2025-06-14','09:40','10:30',3,
  'https://kcd.gt/slides/argocd.pdf',NULL),
(26,1,'Microservicios con Dapr & Kubernetes','charla',4,'2025-06-14','11:00','11:35',3,
  'https://kcd.gt/slides/dapr-microservices.pdf','https://github.com/demo/dapr-demo'),
(27,1,'Backend Gaming con K8s + Redis','charla',3,'2025-06-14','11:35','12:10',3,
  'https://kcd.gt/slides/redis-games.pdf','https://github.com/demo/redis-games');

/*----------------------------------------------------------------
  7) SESSION_SPEAKERS
----------------------------------------------------------------*/
INSERT INTO session_speakers (session_id,speaker_id,is_primary,speaker_order) VALUES
( 1, 1,TRUE,0),( 1, 2,FALSE,1),
( 4, 3,TRUE,0),
( 5, 4,TRUE,0),
( 6, 5,TRUE,0),
( 7, 6,TRUE,0),
( 8, 7,TRUE,0),
( 9, 8,TRUE,0),
(10, 9,TRUE,0),
(11,10,TRUE,0),(12,11,TRUE,0),(13,12,TRUE,0),(14,13,TRUE,0),(15,14,TRUE,0),
(16,15,TRUE,0),(17,16,TRUE,0),(18,17,TRUE,0),(19,18,TRUE,0),
(20,19,TRUE,0),(21,20,TRUE,0),(22,21,TRUE,0),(23,22,TRUE,0),
(24,23,TRUE,0),(25,24,TRUE,0),(26,25,TRUE,0),(27,26,TRUE,0);

/*----------------------------------------------------------------
  8) SESSION_TAGS
----------------------------------------------------------------*/
INSERT INTO session_tags (session_id,tag_id) VALUES
/* Landívar */
( 1,1),( 1,2),( 1,20),
( 4,11),( 4,6),
( 5,12),( 5,6),
( 6,12),( 6,6),
( 7,13),( 7,26),( 7,1),
( 8,3),( 8,23),
( 9,21),( 9,8),( 9,9),
(10,20),(10,8),(10,1),
/* El Obispo */
(11,5),(11,4),(11,6),
(12,1),(12,6),
(13,9),(13,8),
(14,4),(14,16),(14,3),
(15,3),(15,2),
(16,14),(16,23),
(17,6),
(18,10),(18,1),
(19,2),
/* Don Pedro */
(20,18),(20,6),(20,23),
(21,4),(21,16),
(22,1),(22,2),
(23,15),(23,3),
(24,24),(24,7),(24,6),
(25,16),(25,4),(25,5),
(26,19),(26,6),
(27,17),(27,22),(27,3),(27,1);