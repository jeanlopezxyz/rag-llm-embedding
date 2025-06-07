# Dockerfile
FROM python:3.11

# Metadatos
LABEL maintainer="your-team@company.com"
LABEL description="Event Embeddings Generator for PGVector"
LABEL version="1.0.0"

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Establecer directorio de trabajo
WORKDIR /app

# Actualizar pip (opcional, buena práctica)
RUN pip install --upgrade pip

# Copiar y instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Actualizar sentence-transformers para evitar el warning de versión
RUN pip install --upgrade sentence-transformers

# Verificar instalación
RUN python -c "import numpy; print(f'NumPy: {numpy.__version__}')" && \
    python -c "import psycopg2; print(f'psycopg2: {psycopg2.__version__}')" && \
    python -c "import pgvector; print(f'pgvector installed')" && \
    python -c "import sentence_transformers; print(f'sentence-transformers: {sentence_transformers.__version__}')"

# Copiar código fuente
COPY sql/ /app/sql/
COPY src/ /app/src/
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# Variables de entorno (usar HF_HOME en lugar de TRANSFORMERS_CACHE)
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    HF_HOME="/cache/.cache" \
    SENTENCE_TRANSFORMERS_HOME="/cache/.cache" \
    TOKENIZERS_PARALLELISM=false

# Crear directorio de cache
RUN mkdir -p /cache/.cache && chmod 777 /cache

# Entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["generate-embeddings"]
