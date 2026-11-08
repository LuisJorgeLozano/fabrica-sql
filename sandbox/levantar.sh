#!/usr/bin/env bash
# Levanta el sandbox de SQL Server de la fábrica. Lo ejecuta una PERSONA, nunca un agente.
#
# - --platform linux/amd64: en Mac con chip Apple, Docker lo emula con Rosetta.
# - --env-file .env: la contraseña entra al contenedor sin pasar por Python ni por ningún agente.
# - -p 127.0.0.1:14333:1433: solo tu Mac puede conectarse (no queda expuesto a tu red).
# - -v "$PWD/bd:/bd:ro": SQL Server LEE los scripts de bd/, pero no puede escribir en tu proyecto.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Falta .env. Corre: cp .env.example .env  (y cambia la contraseña)"
  exit 1
fi

docker rm -f fabrica-sql >/dev/null 2>&1 || true
docker run -d --name fabrica-sql \
  --platform linux/amd64 \
  --env-file .env \
  -p 127.0.0.1:14333:1433 \
  -v "$PWD/bd:/bd:ro" \
  mcr.microsoft.com/mssql/server:2022-latest >/dev/null

echo "Esperando a que SQL Server arranque (puede tardar hasta 2 minutos la primera vez)..."
for _ in $(seq 1 60); do
  if docker exec fabrica-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -Q "SELECT 1" >/dev/null 2>&1; then
    echo "Sandbox listo: servidor localhost,14333 · usuario sa"
    exit 0
  fi
  sleep 2
done
echo "SQL Server no arrancó. Revisa el log con: docker logs fabrica-sql"
exit 1