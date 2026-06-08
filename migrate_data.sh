#!/bin/bash
set -e

echo "=== Начало переноса данных ==="

# 1. Восстановление MariaDB
if [ -f "infra_watch_dump.sql" ]; then
  echo "Восстановление дампа MariaDB..."
  podman exec -i mariadb mariadb -u root -proot123 infra_watch <infra_watch_dump.sql
  echo "✅ MariaDB восстановлена."
else
  echo "⚠️ Файл infra_watch_dump.sql не найден. Пропуск."
fi

# 2. Восстановление InfluxDB
if [ -f "influx_settings.tar" ]; then
  echo "Копирование и распаковка архива InfluxDB..."
  podman cp influx_settings.tar influxdb:/tmp/influx_settings.tar

  # Распаковка в директорию данных и исправление прав
  podman exec influxdb sh -c "cd /var/lib/influxdb2 && tar -xvf /tmp/influx_settings.tar --strip-components=1 || true"
  podman exec influxdb chown -R influxdb:influxdb /var/lib/influxdb2

  echo "Перезапуск InfluxDB для применения настроек..."
  podman restart influxdb
  echo "✅ InfluxDB восстановлена."
else
  echo "⚠️ Файл influx_settings.tar не найден. Пропуск."
fi

echo "=== Перенос данных завершён ==="
