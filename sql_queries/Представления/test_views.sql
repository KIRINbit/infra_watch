-- ========================================
-- InfraWatch: Тестирование представлений
-- ========================================

SELECT '=== ТЕСТ 1: v_active_incidents_full ===' AS '';
SELECT incident_id, severity, status, hostname, service_name, team_name, target_uptime_pct
FROM v_active_incidents_full;

SELECT '=== ТЕСТ 2: v_server_sla_report ===' AS '';
SELECT hostname, os_type, team_name, target_uptime_pct, 
       total_incidents, critical_incidents, total_downtime_minutes
FROM v_server_sla_report
LIMIT 10;

SELECT '=== ПРОВЕРКА: список созданных представлений ===' AS '';
SELECT TABLE_NAME 
FROM information_schema.VIEWS 
WHERE TABLE_SCHEMA = 'infra_watch'
ORDER BY TABLE_NAME;
