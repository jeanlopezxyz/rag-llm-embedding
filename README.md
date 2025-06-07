# Event Embeddings Generator

Sistema para generar embeddings de eventos, sesiones y ponentes usando Sentence Transformers y almacenarlos en PGVector para búsqueda semántica.

## Características

- 🚀 Generación de embeddings para sesiones y speakers
- 🔄 Modo incremental para procesar solo cambios
- 🐳 Containerizado con Docker
- ☸️ Listo para Kubernetes con Helm
- 📊 Logging detallado y tracking de progreso
- 🔧 Configuración flexible via variables de entorno

## Estructura del Proyecto

```
event-embeddings-generator/
├── src/
│   ├── __init__.py           # Package initialization
│   ├── config.py             # Configuration management
│   ├── utils.py              # Utility functions
│   └── generate_embeddings.py # Main script
├── sql/
│   ├── 01-schema-source.sql  # PostgreSQL schema
│   └── 02-test-data.sql      # Test data
├── k8s/
│   └── job.yaml              # Kubernetes Job
├── docker-entrypoint.sh      # Container entrypoint
├── Dockerfile                # Container definition
├── docker-compose.yml        # Local development
├── requirements.txt          # Python dependencies
└── Makefile                  # Build automation
```

## Inicio Rápido

### Desarrollo Local

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd event-embeddings-generator
   ```

2. **Ejecutar con Docker Compose**
   ```bash
   make run
   ```

3. **Ver logs**
   ```bash
   docker-compose logs -f embeddings-generator
   ```

### Producción (Kubernetes)

1. **Construir y publicar imagen**
   ```bash
   make push
   ```

2. **Desplegar con Helm**
   ```bash
   helm upgrade --install rag-llm ./chart \
     --values values.yaml \
     --namespace rag-llm
   ```

## Configuración

### Variables de Entorno

#### Base de Datos Fuente (PostgreSQL)
- `DB_SOURCE_HOST`: Host de PostgreSQL
- `DB_SOURCE_PORT`: Puerto (default: 5432)
- `DB_SOURCE_NAME`: Nombre de la base de datos
- `DB_SOURCE_USER`: Usuario
- `DB_SOURCE_PASSWORD`: Contraseña

#### Base de Datos Destino (PGVector)
- `DB_DEST_HOST`: Host de PGVector
- `DB_DEST_PORT`: Puerto (default: 5432)
- `DB_DEST_NAME`: Nombre de la base de datos
- `DB_DEST_USER`: Usuario
- `DB_DEST_PASSWORD`: Contraseña

#### Configuración de Embeddings
- `EMBEDDING_MODEL_NAME`: Modelo a usar (default: sentence-transformers/multi-qa-mpnet-base-dot-v1)
- `EMBEDDING_DIM`: Dimensión de embeddings (default: 768)
- `EMBEDDING_DEVICE`: Dispositivo (cpu/cuda)
- `BATCH_SIZE`: Tamaño de batch (default: 32)

#### Procesamiento
- `INCREMENTAL_MODE`: auto/true/false
- `LOOKBACK_HOURS`: Horas hacia atrás en modo incremental
- `INIT_DBS`: Inicializar bases de datos (true/false)
- `LOAD_TEST_DATA`: Cargar datos de prueba (true/false)

## Comandos del Contenedor

El contenedor soporta varios comandos:

- `generate-embeddings`: Ejecuta el proceso completo (default)
- `init-only`: Solo inicializa las bases de datos
- `test-connection`: Prueba las conexiones
- `shell`: Abre un shell para debugging

Ejemplo:
```bash
docker run <image> test-connection
```

## Arquitectura

### Flujo de Datos

```
PostgreSQL (Eventos) → Embeddings Generator → PGVector
     ↓                         ↓                   ↓
  Sesiones              Sentence Transformer   Vectores
  Speakers                     ↓              Búsqueda
   Tags                   Embeddings          Semántica
```

### Tablas Generadas en PGVector

1. **session_embeddings**: Embeddings de sesiones
2. **speaker_embeddings**: Embeddings de ponentes
3. **embeddings_sync_log**: Log de sincronizaciones

## Consultas de Ejemplo

### Buscar sesiones similares
```sql
SELECT session_name, 
       1 - (embedding <=> query_embedding) as similarity
FROM session_embeddings
ORDER BY similarity DESC
LIMIT 10;
```

### Sesiones por speaker
```sql
SELECT session_name, start_time, location
FROM session_embeddings
WHERE 'Carlos Azaustre' = ANY(speaker_names)
ORDER BY start_time;
```

## Desarrollo

### Ejecutar tests
```bash
make test
```

### Formatear código
```bash
black src/
isort src/
```

### Type checking
```bash
mypy src/
```

## Monitoreo

### Kubernetes
```bash
# Ver estado del Job
kubectl get jobs -n rag-llm

# Ver logs
kubectl logs -f job/populate-events-embeddings -n rag-llm

# Ver métricas en la BD
kubectl exec -it pgvector-pod -- psql -U vector_user -d vector_db \
  -c "SELECT * FROM embeddings_sync_log ORDER BY sync_timestamp DESC LIMIT 5;"
```

## Troubleshooting

### El Job falla al conectar
1. Verificar que los secrets existan
2. Comprobar conectividad de red
3. Revisar logs: `kubectl logs job/<job-name>`

### Embeddings no se generan
1. Verificar que el modelo se descarga correctamente
2. Comprobar memoria disponible
3. Revisar el device configurado (cpu/cuda)

### Modo incremental no funciona
1. Verificar que existan sincronizaciones previas
2. Comprobar el valor de INCREMENTAL_MODE
3. Revisar LOOKBACK_HOURS

## Licencia

[Tu licencia aquí]

## Contribuir

1. Fork el proyecto
2. Crea tu feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request
