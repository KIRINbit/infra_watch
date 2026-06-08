#!/bin/bash
set -euo pipefail

# ==================== НАСТРОЙКИ ====================
CONTAINER_NAME="mariadb"
CSV_DIR="/home/kirinbit/Проекты/infra_watch/Тестовые данные"
MYSQL_USER="root"
MYSQL_PASSWORD="root123"
MYSQL_DATABASE="infra_watch"
CONTAINER_CSV_DIR="/tmp/csv_import"
# ===================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

error_exit() {
  echo -e "${RED}ОШИБКА: $1${NC}" >&2
  exit 1
}

# Копирование CSV в контейнер
podman exec "$CONTAINER_NAME" mkdir -p "$CONTAINER_CSV_DIR"
for file in users.csv teams.csv servers.csv services.csv server_services.csv \
  alert_rules.csv incidents.csv maintenance_windows.csv \
  sla_policies.csv system_settings.csv; do
  if [ ! -f "$CSV_DIR/$file" ]; then
    error_exit "Отсутствует файл: $CSV_DIR/$file"
  fi
  podman cp "$CSV_DIR/$file" "$CONTAINER_NAME:$CONTAINER_CSV_DIR/"
done

# SQL-загрузка
SQL_LOAD=$(
  cat <<'EOF'
USE infra_watch;
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

LOAD DATA LOCAL INFILE '/tmp/csv_import/users.csv' IGNORE INTO TABLE users
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (username, password_hash, role, email, created_at);

LOAD DATA LOCAL INFILE '/tmp/csv_import/teams.csv' IGNORE INTO TABLE teams
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (name, description, lead_user_id);

LOAD DATA LOCAL INFILE '/tmp/csv_import/servers.csv' IGNORE INTO TABLE servers
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (hostname, ip_address, os_type, location, status, team_id);

LOAD DATA LOCAL INFILE '/tmp/csv_import/services.csv' IGNORE INTO TABLE services
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (name, port, protocol, description);

LOAD DATA LOCAL INFILE '/tmp/csv_import/server_services.csv' IGNORE INTO TABLE server_services
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (server_id, service_id, status, last_checked);

LOAD DATA LOCAL INFILE '/tmp/csv_import/alert_rules.csv' IGNORE INTO TABLE alert_rules
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (server_service_id, metric_name, threshold_min, threshold_max, is_active);

LOAD DATA LOCAL INFILE '/tmp/csv_import/incidents.csv' IGNORE INTO TABLE incidents
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (alert_rule_id, triggered_at, resolved_at, severity, status, description);

LOAD DATA LOCAL INFILE '/tmp/csv_import/maintenance_windows.csv' IGNORE INTO TABLE maintenance_windows
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (server_id, start_time, end_time, reason, created_by_user_id);

LOAD DATA LOCAL INFILE '/tmp/csv_import/sla_policies.csv' IGNORE INTO TABLE sla_policies
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (team_id, target_uptime_pct, measurement_period_days);

LOAD DATA LOCAL INFILE '/tmp/csv_import/system_settings.csv' IGNORE INTO TABLE system_settings
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS (setting_key, setting_value, updated_by_user_id);

SET FOREIGN_KEY_CHECKS = 1;
EOF
)

echo "Загрузка данных..."
if podman exec -i "$CONTAINER_NAME" mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --local-infile=1 <<<"$SQL_LOAD"; then
  echo -e "${GREEN}Загрузка завершена${NC}"
else
  error_exit "Ошибка при загрузке"
fi
