#!/bin/bash
set -euo pipefail

# ==================== НАСТРОЙКИ ====================
CSV_DIR="$(cd "$(dirname "$0")" && pwd)"

# Авто-выбор контейнерного движка
if command -v podman >/dev/null 2>&1; then
  RUNTIME="podman"
  COMPOSE="podman compose"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME="docker"
  COMPOSE="docker compose"
else
  echo "ОШИБКА: не найден ни podman, ни docker" >&2
  exit 1
fi

CONTAINER_NAME="${CONTAINER_NAME:-mariadb}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-root123}"
MYSQL_DATABASE="${MYSQL_DATABASE:-infra_watch}"
CONTAINER_CSV_DIR="/tmp/csv_import"
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${CYAN}[load_data]${NC} $*"; }
error_exit() {
  echo -e "${RED}ОШИБКА: $1${NC}" >&2
  exit 1
}

# Проверяем, что контейнер запущен
if ! $RUNTIME ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  error_exit "Контейнер '$CONTAINER_NAME' не запущен. Сначала: $COMPOSE up -d mariadb"
fi

# Копирование CSV в контейнер
$RUNTIME exec "$CONTAINER_NAME" mkdir -p "$CONTAINER_CSV_DIR"
for file in users.csv teams.csv servers.csv services.csv server_services.csv \
  alert_rules.csv incidents.csv maintenance_windows.csv \
  sla_policies.csv system_settings.csv; do
  if [ ! -f "$CSV_DIR/$file" ]; then
    error_exit "Отсутствует файл: $CSV_DIR/$file"
  fi
  $RUNTIME cp "$CSV_DIR/$file" "$CONTAINER_NAME:$CONTAINER_CSV_DIR/"
  log "скопирован $file"
done

# SQL-загрузка
SQL_LOAD=$(
  cat <<EOSQL
USE $MYSQL_DATABASE;
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE system_settings;
TRUNCATE TABLE sla_policies;
TRUNCATE TABLE maintenance_windows;
TRUNCATE TABLE incidents;
TRUNCATE TABLE alert_rules;
TRUNCATE TABLE server_services;
TRUNCATE TABLE services;
TRUNCATE TABLE servers;
TRUNCATE TABLE teams;
TRUNCATE TABLE users;

SET GLOBAL local_infile = ON;

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/users.csv' IGNORE INTO TABLE users
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, username, password_hash, role, email, created_at);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/teams.csv' IGNORE INTO TABLE teams
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, name, description, lead_user_id);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/servers.csv' IGNORE INTO TABLE servers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, hostname, ip_address, os_type, location, status, team_id);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/services.csv' IGNORE INTO TABLE services
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, name, port, protocol, description);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/server_services.csv' IGNORE INTO TABLE server_services
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, server_id, service_id, status, last_checked);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/alert_rules.csv' IGNORE INTO TABLE alert_rules
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, server_service_id, metric_name, threshold_min, threshold_max, is_active);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/incidents.csv' IGNORE INTO TABLE incidents
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, alert_rule_id, triggered_at, resolved_at, severity, status, description);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/maintenance_windows.csv' IGNORE INTO TABLE maintenance_windows
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, server_id, start_time, end_time, reason, created_by_user_id);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/sla_policies.csv' IGNORE INTO TABLE sla_policies
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, team_id, target_uptime_pct, measurement_period_days);

LOAD DATA LOCAL INFILE '$CONTAINER_CSV_DIR/system_settings.csv' IGNORE INTO TABLE system_settings
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (id, setting_key, setting_value, updated_at, updated_by_user_id);

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'USERS' AS table_name, COUNT(*) AS rows_loaded FROM users
UNION ALL SELECT 'TEAMS', COUNT(*) FROM teams
UNION ALL SELECT 'SERVERS', COUNT(*) FROM servers
UNION ALL SELECT 'SERVICES', COUNT(*) FROM services
UNION ALL SELECT 'SERVER_SERVICES', COUNT(*) FROM server_services
UNION ALL SELECT 'ALERT_RULES', COUNT(*) FROM alert_rules
UNION ALL SELECT 'INCIDENTS', COUNT(*) FROM incidents
UNION ALL SELECT 'MAINTENANCE_WINDOWS', COUNT(*) FROM maintenance_windows
UNION ALL SELECT 'SLA_POLICIES', COUNT(*) FROM sla_policies
UNION ALL SELECT 'SYSTEM_SETTINGS', COUNT(*) FROM system_settings;
EOSQL
)

log "Загрузка данных в MariaDB..."
if $RUNTIME exec -i "$CONTAINER_NAME" mariadb -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --local-infile=1 <<<"$SQL_LOAD"; then
  echo -e "${GREEN}✅ Загрузка CSV завершена${NC}"
else
  error_exit "Ошибка при загрузке"
fi
