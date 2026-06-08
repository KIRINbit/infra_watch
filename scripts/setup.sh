#!/bin/bash
set -euo pipefail

# ============================================================
# InfraWatch: полный bootstrap с нуля
#   1. Поднимает контейнеры (mariadb + influxdb + web)
#   2. Ждёт готовности обеих БД
#   3. Создаёт схему (create_tables.sql)
#   4. Создаёт представления и процедуры/функции
#   5. Заливает тестовые CSV (опционально)
#   6. Генерирует демо-метрики в InfluxDB (опционально)
#
# Использование:
#   ./scripts/setup.sh                  # всё по умолчанию
#   ./scripts/setup.sh --no-seed        # без CSV и метрик
#   ./scripts/setup.sh --reset          # снести тома и поднять заново
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CSV_DIR="$PROJECT_DIR/Тестовые данные"
SEED_CSV=1
SEED_METRICS=1
RESET=0

for arg in "$@"; do
  case $arg in
    --no-seed)        SEED_CSV=0; SEED_METRICS=0 ;;
    --no-csv)         SEED_CSV=0 ;;
    --no-metrics)     SEED_METRICS=0 ;;
    --reset)          RESET=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Неизвестный аргумент: $arg"; exit 1 ;;
  esac
done

# ---------- Выбор контейнерного движка ----------
if command -v podman >/dev/null 2>&1; then
  RUNTIME="podman"; COMPOSE="podman compose"
elif command -v docker >/dev/null 2>&1; then
  RUNTIME="docker"; COMPOSE="docker compose"
else
  echo "❌ Не найден ни podman, ни docker. Установите один из них." >&2
  exit 1
fi

# ---------- Цвета ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${CYAN}▶${NC} $*"; }
ok()    { echo -e "${GREEN}✔${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
fail()  { echo -e "${RED}✖${NC} $*" >&2; exit 1; }

cd "$PROJECT_DIR"

# ---------- Шаг 1. Опциональный сброс ----------
if [ "$RESET" = "1" ]; then
  warn "Сброс контейнеров и томов..."
  $COMPOSE down -v || true
fi

# ---------- Шаг 2. Запуск контейнеров ----------
info "Запуск стека ($COMPOSE up -d)..."
$COMPOSE up -d --build

# ---------- Шаг 3. Ожидание MariaDB ----------
info "Ожидание готовности MariaDB..."
for i in $(seq 1 60); do
  if $RUNTIME exec mariadb mariadb -uroot -proot123 -e "SELECT 1" >/dev/null 2>&1; then
    ok "MariaDB готова"; break
  fi
  [ $i -eq 60 ] && fail "MariaDB не поднялась за 60 секунд"
  sleep 1
done

# ---------- Шаг 4. Ожидание InfluxDB ----------
info "Ожидание готовности InfluxDB..."
for i in $(seq 1 60); do
  if curl -sf http://localhost:8086/health >/dev/null 2>&1; then
    ok "InfluxDB готова"; break
  fi
  [ $i -eq 60 ] && fail "InfluxDB не поднялась за 60 секунд"
  sleep 1
done

# ---------- Шаг 5. Схема ----------
info "Применение create_tables.sql..."
$RUNTIME exec -i mariadb mariadb -uroot -proot123 < "$PROJECT_DIR/create_tables.sql"
ok "Схема создана"

# ---------- Шаг 6. Представления и процедуры ----------
if [ -f "$PROJECT_DIR/sql_queries/Представления/create_views.sql" ]; then
  info "Создание представлений..."
  # Файл содержит DELIMITER-директивы — применим напрямую в mariadb (там CREATE VIEW их не использует)
  $RUNTIME exec -i mariadb mariadb -uroot -proot123 infra_watch < "$PROJECT_DIR/sql_queries/Представления/create_views.sql"
  ok "Представления созданы"
fi

if [ -f "$PROJECT_DIR/sql_queries/Хранимые процедуры и функции/create_objects.sql" ]; then
  info "Создание процедур и функций..."
  $RUNTIME exec -i mariadb mariadb -uroot -proot123 < "$PROJECT_DIR/sql_queries/Хранимые процедуры и функции/create_objects.sql" || \
    warn "Часть объектов не создалась (это нормально, если они уже есть)"
fi

# ---------- Шаг 7. Засев CSV ----------
if [ "$SEED_CSV" = "1" ] && [ -f "$CSV_DIR/load_data.sh" ]; then
  info "Загрузка тестовых CSV..."
  bash "$CSV_DIR/load_data.sh"
  ok "CSV-данные загружены"
fi

# ---------- Шаг 8. Демо-метрики в InfluxDB ----------
if [ "$SEED_METRICS" = "1" ] && [ -f "$PROJECT_DIR/populate_influx.sh" ]; then
  info "Генерация демо-метрик в InfluxDB (24 точки)..."
  bash "$PROJECT_DIR/populate_influx.sh" || warn "Не удалось записать метрики (возможно, бакет ещё не настроен)"
fi

# ---------- Шаг 9. Итог ----------
echo
ok "==============================================="
ok " InfraWatch развёрнут!"
ok " UI:       http://localhost:8080"
ok " MariaDB:  localhost:3306  (root/root123)"
ok " InfluxDB: http://localhost:8086"
ok "==============================================="
