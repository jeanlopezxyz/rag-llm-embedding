#!/bin/bash

set -e

PROJECT_ROOT="event-embeddings-generator"

echo "🛠️ Creando estructura del proyecto: $PROJECT_ROOT"

mkdir -p $PROJECT_ROOT/{src,sql,k8s,tests}

touch $PROJECT_ROOT/{Dockerfile,docker-entrypoint.sh,requirements.txt,Makefile,.dockerignore,.gitignore,README.md}
touch $PROJECT_ROOT/src/{__init__.py,generate_embeddings.py,config.py,utils.py}
touch $PROJECT_ROOT/sql/{01-schema-source.sql,02-test-data.sql,03-schema-vector.sql}
touch $PROJECT_ROOT/k8s/{job.yaml,cronjob.yaml,secrets.yaml,configmap.yaml}
touch $PROJECT_ROOT/tests/{__init__.py,test_embeddings.py,test_connections.py}

# Agregar comentarios iniciales a los archivos clave
echo "# Dockerfile para el generador de embeddings" > $PROJECT_ROOT/Dockerfile
echo "# Script de entrada para el contenedor Docker" > $PROJECT_ROOT/docker-entrypoint.sh
echo "# Requisitos de Python" > $PROJECT_ROOT/requirements.txt
echo "# Makefile con comandos útiles del proyecto" > $PROJECT_ROOT/Makefile
echo "# Ignorar archivos para Docker" > $PROJECT_ROOT/.dockerignore
echo "# Ignorar archivos para Git" > $PROJECT_ROOT/.gitignore
echo "# Proyecto para generar embeddings de eventos" > $PROJECT_ROOT/README.md

echo "# Script principal para generar embeddings" > $PROJECT_ROOT/src/generate_embeddings.py
echo "# Configuración del proyecto" > $PROJECT_ROOT/src/config.py
echo "# Utilidades auxiliares" > $PROJECT_ROOT/src/utils.py

echo "-- Esquema fuente para eventos en PostgreSQL" > $PROJECT_ROOT/sql/01-schema-source.sql
echo "-- Datos de prueba opcionales" > $PROJECT_ROOT/sql/02-test-data.sql
echo "-- Esquema opcional para PGVector" > $PROJECT_ROOT/sql/03-schema-vector.sql

echo "# Job de Kubernetes" > $PROJECT_ROOT/k8s/job.yaml
echo "# CronJob de Kubernetes" > $PROJECT_ROOT/k8s/cronjob.yaml
echo "# Secretos de Kubernetes" > $PROJECT_ROOT/k8s/secrets.yaml
echo "# ConfigMap de Kubernetes" > $PROJECT_ROOT/k8s/configmap.yaml

echo "# Pruebas para embeddings" > $PROJECT_ROOT/tests/test_embeddings.py
echo "# Pruebas de conexión a servicios" > $PROJECT_ROOT/tests/test_connections.py

echo "✅ Proyecto creado exitosamente en ./$PROJECT_ROOT"
