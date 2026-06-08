# InfraWatch

> Веб-система мониторинга ИТ-инфраструктуры на Go + MariaDB + InfluxDB v2.

Веб-интерфейс с вкладками:

| Вкладка                | Что умеет                                                                 |
|------------------------|---------------------------------------------------------------------------|
| **Панель**             | Сводка по серверам, последние метрики из InfluxDB, быстрые действия        |
| **Серверы**            | CRUD: добавление, **редактирование**, удаление серверов                   |
| **Инциденты**          | Принять (`acknowledged`) и закрыть (`resolved`) любой активный инцидент    |
| **Правила алертов**    | Изменить пороги `min`/`max`, включить/выключить правило                    |
| **Отчёты**             | SLA-витрина из `v_server_sla_report` + **экспорт в CSV**                   |
| **Настройки**          | Inline-редактирование параметров `system_settings`                        |

---

## 🚀 Быстрый старт (1 команда)

```bash
git clone <repo> && cd infra_watch
./scripts/setup.sh
```

Скрипт автоматически:

1. поднимет `mariadb`, `influxdb`, `web` через compose;
2. дождётся готовности обеих БД;
3. применит `create_tables.sql`, представления и хранимые процедуры/функции;
4. зальёт тестовые CSV (50 серверов, 30 инцидентов, …);
5. сгенерирует 24 демо-точки в InfluxDB.

После завершения:

| Сервис       | Адрес                     | Логин      | Пароль       |
|--------------|---------------------------|------------|--------------|
| Web UI       | http://localhost:8080     | —          | —            |
| MariaDB      | localhost:3306            | `root`     | `root123`    |
| InfluxDB     | http://localhost:8086     | `YvR1y3o…` | — (в `main.go`) |

> Скрипт сам определяет, что у вас стоит — `docker` или `podman`.

### Другие полезные скрипты

```bash
./scripts/setup.sh --no-seed   # поднять контейнеры и схему, но без демо-данных
./scripts/setup.sh --reset     # снести тома и начать с нуля
./scripts/logs.sh web          # tail логов веб-контейнера
./scripts/stop.sh              # остановить стек
```

---

## 🛠 Ручная установка (пошагово)

Если хочется контролировать каждый шаг.

### 1. Предварительные требования

- Go **1.22+** (для локальной сборки вне контейнера)
- Docker **или** Podman с поддержкой Compose
- 2 ГБ свободной RAM

### 2. Поднимите инфраструктуру

```bash
docker compose up -d            # или: podman compose up -d
```

Будут запущены контейнеры `mariadb`, `influxdb`, `infra_watch`.

### 3. Создайте схему MariaDB

```bash
docker exec -i mariadb mariadb -uroot -proot123 < create_tables.sql
docker exec -i mariadb mariadb -uroot -proot123 < "sql_queries/Представления/create_views.sql"
docker exec -i mariadb mariadb -uroot -proot123 < "sql_queries/Хранимые процедуры и функции/create_objects.sql"
```

### 4. (Опционально) загрузите тестовые данные

CSV-файлы лежат в каталоге `Тестовые данные/`. Запуск:

```bash
bash "Тестовые данные/load_data.sh"
```

В конце выведется табличка с количеством загруженных строк по каждой таблице.

### 5. (Опционально) сгенерируйте демо-метрики в InfluxDB

```bash
bash populate_influx.sh
```

Запишет 12 точек `server_metrics` и 12 точек `service_metrics` в бакет `infra_metrics`.

### 6. Откройте UI

```
http://localhost:8080
```

---

## 💻 Локальная разработка (без Docker для web-сервиса)

```bash
# Если есть Nix:
nix develop

# Или просто:
go run ./cmd/infrawatch/main.go
```

Перед запуском убедитесь, что контейнеры `mariadb` и `influxdb` подняты, а Go может до них достучаться (для Go на хосте - поменяйте `mariadb:3306` в `main.go` на `localhost:3306`).

---

## 🗂 Структура проекта

```
.
├── cmd/infrawatch/        # Точка входа (main.go), роутер Chi
├── internal/
│   ├── handlers/          # HTTP-хендлеры (CRUD для всех вкладок)
│   ├── models/            # Структуры данных
│   └── repository/        # Работа с MariaDB и InfluxDB
├── templates/index.html   # Единый SPA-шаблон со всеми вкладками
├── sql_queries/           # Представления, процедуры, аналитика
├── Тестовые данные/       # CSV + load_data.sh
├── scripts/               # setup.sh, logs.sh, stop.sh
├── compose.yml            # mariadb + influxdb + web
├── Dockerfile             # multi-stage сборка Go
├── create_tables.sql      # DDL всей схемы
└── populate_influx.sh     # Генератор демо-метрик
```

---

## 🔌 HTTP-эндпоинты

| Метод | Путь                          | Назначение                                |
|-------|-------------------------------|-------------------------------------------|
| GET   | `/panel`, `/servers`, …       | Рендер вкладки                            |
| POST  | `/servers/add`                | Создать сервер                            |
| POST  | `/servers/edit/{id}`          | Обновить сервер                           |
| POST  | `/servers/delete/{id}`        | Удалить сервер                            |
| POST  | `/incidents/ack/{id}`         | Перевести инцидент в `acknowledged`       |
| POST  | `/incidents/resolve/{id}`     | Закрыть инцидент                          |
| POST  | `/alerts/thresholds/{id}`     | Обновить `threshold_min/max`              |
| POST  | `/alerts/toggle/{id}`         | Включить/выключить правило                |
| POST  | `/settings/update/{id}`       | Изменить значение `system_settings`       |
| GET   | `/reports/export.csv`         | Скачать SLA-отчёт в CSV                   |

Все POST-эндпоинты делают `303 See Other` обратно на исходную вкладку и
передают `?added=1`, `?updated=1`, `?error=…` — это видно как flash-сообщение.

---

## 🩺 Диагностика

```bash
docker compose ps                 # статус контейнеров
./scripts/logs.sh web             # логи Go-приложения
docker exec -it mariadb mariadb -uroot -proot123 -e "SHOW TABLES" infra_watch
curl -s http://localhost:8086/health
```

Типовые проблемы:

| Симптом                                              | Решение                                                  |
|------------------------------------------------------|----------------------------------------------------------|
| `bind: address already in use` на 8080               | `docker compose down`, либо смените порт в `compose.yml` |
| `mariadb:3306: connect: connection refused`          | Подождите 10-15 с, БД ещё стартует                      |
| Пустая таблица «Состояние серверов» на панели        | Запустите `populate_influx.sh`                           |
| `Access denied for user 'root'`                      | Пароль `root123` задан в `compose.yml` и `main.go`       |

---

## 📜 Лицензия

См. [LICENSE](./LICENSE).
