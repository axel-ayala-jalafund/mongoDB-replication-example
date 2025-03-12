#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Este script necesita privilegios de administrador para otorgar permisos correctamente."
  echo "Por favor ejecuta: sudo ./setup-mongodb-replication.sh"
  exit 1
fi

echo "=== Limpiando recursos anteriores ==="
docker stop mongo1 mongo2 mongo3 2>/dev/null
docker rm mongo1 mongo2 mongo3 2>/dev/null

docker network rm mongo-repl-network 2>/dev/null

echo "=== Creando directorios para datos ==="
mkdir -p ./data/mongo1 ./data/mongo2 ./data/mongo3

chmod -R 777 ./data/mongo1 ./data/mongo2 ./data/mongo3
echo "Permisos otorgados a directorios de datos"
