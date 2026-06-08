-- ========================================
-- Тестовые вызовы процедур и функций
-- ========================================

-- Тест процедуры resolve_incident
SELECT '=== Тест процедуры resolve_incident ===' AS info;
CALL resolve_incident(27, 3, @duration);
SELECT @duration AS incident_duration_minutes;
SELECT id, status, triggered_at, resolved_at FROM incidents WHERE id = 27;

-- Тест процедуры schedule_maintenance
SELECT '=== Тест процедуры schedule_maintenance ===' AS info;
CALL schedule_maintenance(
    1,
    '2026-07-15 02:00:00',
    '2026-07-15 04:00:00',
    'Обновление ядра Linux',
    1
);
SELECT mw.id, s.hostname, mw.start_time, mw.end_time, mw.reason
FROM maintenance_windows mw
JOIN servers s ON mw.server_id = s.id
WHERE s.id = 1
ORDER BY mw.id DESC LIMIT 1;
SELECT id, hostname, status FROM servers WHERE id = 1;

-- Тест функции get_incident_duration_minutes
SELECT '=== Тест функции get_incident_duration_minutes ===' AS info;
SELECT 
    25 AS incident_id, get_incident_duration_minutes(25) AS duration_minutes
UNION ALL
SELECT 28, get_incident_duration_minutes(28)
UNION ALL
SELECT 999, get_incident_duration_minutes(999);

-- Тест функции calculate_uptime_percentage
SELECT '=== Тест функции calculate_uptime_percentage ===' AS info;
SELECT 
    s.hostname,
    s.os_type,
    calculate_uptime_percentage(s.id, 90) AS uptime_pct_90d
FROM servers s
WHERE s.id IN (1, 3, 6)
ORDER BY uptime_pct_90d DESC;

-- Проверка наличия созданных объектов
SELECT '=== Проверка созданных объектов ===' AS info;
SELECT ROUTINE_NAME, ROUTINE_TYPE 
FROM information_schema.ROUTINES 
WHERE ROUTINE_SCHEMA = 'infra_watch'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;
