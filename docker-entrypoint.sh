#!/bin/bash
# docker-entrypoint.sh

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Función para esperar a que PostgreSQL esté listo
wait_for_postgres() {
    local host=$1
    local port=$2
    local dbname=$3
    local user=$4
    local password=$5
    local max_attempts=30
    local attempt=1

    log "Esperando a que PostgreSQL esté listo en $host:$port (DB: $dbname) para el usuario $user..."

    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD=$password pg_isready -h "$host" -p "$port" -U "$user" -d "$dbname" >/dev/null 2>&1; then
            log "PostgreSQL está listo!"
            return 0
        fi
        
        warning "Intento $attempt/$max_attempts: PostgreSQL no está listo aún..."
        sleep 2
        attempt=$((attempt + 1))
    done

    error "PostgreSQL no está disponible después de $max_attempts intentos"
    return 1
}

# Función para verificar si las tablas existen
check_tables_exist() {
    local host=$1
    local port=$2
    local dbname=$3
    local user=$4
    local password=$5
    local table_name=$6
    
    local count=$(PGPASSWORD=$password psql -h "$host" -p "$port" -U "$user" -d "$dbname" -tAc \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='$table_name';")
    
    # Verificar que count sea un número
    if [[ "$count" =~ ^[0-9]+$ ]]; then
        echo "$count"
    else
        echo "0"
    fi
}

# Función para inicializar la base de datos fuente
init_source_db() {
    log "Inicializando base de datos fuente..."
    
    # Esperar a que esté lista
    wait_for_postgres "$DB_SOURCE_HOST" "$DB_SOURCE_PORT" "$DB_SOURCE_NAME" "$DB_SOURCE_USER" "$DB_SOURCE_PASSWORD" || return 1
    
    # Verificar si las tablas ya existen
    local tables_exist=$(check_tables_exist "$DB_SOURCE_HOST" "$DB_SOURCE_PORT" "$DB_SOURCE_NAME" "$DB_SOURCE_USER" "$DB_SOURCE_PASSWORD" "schedules")
    
    if [ "$tables_exist" -eq "0" ]; then
        log "Creando schema en base de datos fuente (la tabla 'schedules' no fue encontrada)..."
        PGPASSWORD=$DB_SOURCE_PASSWORD psql -h "$DB_SOURCE_HOST" -p "$DB_SOURCE_PORT" -U "$DB_SOURCE_USER" -d "$DB_SOURCE_NAME" -f /app/sql/01-schema-source.sql
        
        # Cargar datos de prueba si está habilitado
        if [ "${LOAD_TEST_DATA:-false}" = "true" ]; then
            log "Cargando datos de prueba..."
            PGPASSWORD=$DB_SOURCE_PASSWORD psql -h "$DB_SOURCE_HOST" -p "$DB_SOURCE_PORT" -U "$DB_SOURCE_USER" -d "$DB_SOURCE_NAME" -f /app/sql/02-test-data.sql
        fi
    else
        log "Las tablas ya existen en la base de datos fuente (encontradas $tables_exist tablas)"
    fi
}

# Función para inicializar PGVector
init_vector_db() {
    log "Inicializando base de datos de vectores..."
    
    # Esperar a que esté lista
    wait_for_postgres "$DB_DEST_HOST" "$DB_DEST_PORT" "$DB_DEST_NAME" "$DB_DEST_USER" "$DB_DEST_PASSWORD" || return 1
    
    # Verificar si las tablas ya existen
    local tables_exist=$(check_tables_exist "$DB_DEST_HOST" "$DB_DEST_PORT" "$DB_DEST_NAME" "$DB_DEST_USER" "$DB_DEST_PASSWORD" "session_embeddings")
    
    if [ "$tables_exist" -eq "0" ]; then
        log "Creando schema en base de datos de vectores..."
        
        # Aplicar schema completo de PGVector
        if [ -f "/app/sql/03-schema-vector.sql" ]; then
            log "Aplicando schema completo de PGVector..."
            PGPASSWORD=$DB_DEST_PASSWORD psql -h "$DB_DEST_HOST" -p "$DB_DEST_PORT" -U "$DB_DEST_USER" -d "$DB_DEST_NAME" -f /app/sql/03-schema-vector.sql
            
            if [ $? -eq 0 ]; then
                log "Schema de PGVector creado exitosamente"
            else
                error "Error al crear schema de PGVector"
                return 1
            fi
        else
            error "Archivo de schema PGVector no encontrado: /app/sql/03-schema-vector.sql"
            return 1
        fi
    else
        log "Las tablas ya existen en PGVector (tabla 'session_embeddings' encontrada)"
    fi
    
    log "PGVector inicializado correctamente"
}

# Función principal
main() {
    local cmd="${1:-generate-embeddings}"
    
    log "Iniciando Event Embeddings Generator..."
    log "Comando: $cmd"
    
    # Validar variables de entorno requeridas
    if [ -z "$DB_SOURCE_HOST" ] || [ -z "$DB_DEST_HOST" ]; then
        error "Variables de entorno DB_SOURCE_HOST y DB_DEST_HOST son requeridas"
        exit 1
    fi
    
    case "$cmd" in
        "generate-embeddings")
            # Inicializar bases de datos si está habilitado
            if [ "${INIT_DBS:-true}" = "true" ]; then
                init_source_db || exit 1
                init_vector_db || exit 1
            fi
            
            # Ejecutar el script Python
            log "Ejecutando generación de embeddings..."
            exec python /app/src/generate_embeddings.py
            ;;
            
        "init-only")
            # Solo inicializar las bases de datos
            init_source_db || exit 1
            init_vector_db || exit 1
            log "Inicialización completada"
            ;;
            
        "test-connection")
            # Probar conexiones
            log "Probando conexiones..."
            wait_for_postgres "$DB_SOURCE_HOST" "$DB_SOURCE_PORT" "$DB_SOURCE_NAME" "$DB_SOURCE_USER" "$DB_SOURCE_PASSWORD" || exit 1
            wait_for_postgres "$DB_DEST_HOST" "$DB_DEST_PORT" "$DB_DEST_NAME" "$DB_DEST_USER" "$DB_DEST_PASSWORD" || exit 1
            log "Todas las conexiones están funcionando"
            ;;
            
        "shell")
            # Shell interactivo para debugging
            exec /bin/bash
            ;;
            
        *)
            # Comando personalizado
            exec "$@"
            ;;
    esac
}

# Ejecutar función principal
main "$@"
