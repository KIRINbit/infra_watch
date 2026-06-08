-- ========================================
-- InfraWatch: Представления (VIEW)
-- ========================================

DROP VIEW IF EXISTS v_active_incidents_full;
DROP VIEW IF EXISTS v_server_sla_report;

-- Представление 1: Витрина активных инцидентов
CREATE OR REPLACE VIEW v_active_incidents_full AS
SELECT 
    i.id AS incident_id,
    i.severity,
    i.status,
    i.triggered_at,
    i.description AS incident_description,
    ar.metric_name,
    ar.threshold_min,
    ar.threshold_max,
    s.hostname,
    s.ip_address,
    s.os_type,
    svc.name AS service_name,
    svc.port AS service_port,
    t.name AS team_name,
    sp.target_uptime_pct
FROM incidents i
JOIN alert_rules ar ON i.alert_rule_id = ar.id
JOIN server_services ss ON ar.server_service_id = ss.id
JOIN servers s ON ss.server_id = s.id
JOIN services svc ON ss.service_id = svc.id
JOIN teams t ON s.team_id = t.id
LEFT JOIN sla_policies sp ON t.id = sp.team_id
WHERE i.status IN ('open', 'acknowledged')
ORDER BY i.triggered_at DESC;

-- Представление 2: SLA-отчёт по серверам
CREATE OR REPLACE VIEW v_server_sla_report AS
SELECT 
    s.id AS server_id,
    s.hostname,
    s.os_type,
    s.status AS server_status,
    t.name AS team_name,
    sp.target_uptime_pct,
    sp.measurement_period_days,
    COUNT(i.id) AS total_incidents,
    SUM(CASE WHEN i.severity = 'critical' THEN 1 ELSE 0 END) AS critical_incidents,
    COALESCE(SUM(TIMESTAMPDIFF(MINUTE,
        GREATEST(i.triggered_at, DATE_SUB(NOW(), INTERVAL sp.measurement_period_days DAY)),
        COALESCE(i.resolved_at, NOW())
    )), 0) AS total_downtime_minutes
FROM servers s
JOIN teams t ON s.team_id = t.id
LEFT JOIN sla_policies sp ON t.id = sp.team_id
LEFT JOIN server_services ss ON s.id = ss.server_id
LEFT JOIN alert_rules ar ON ss.id = ar.server_service_id
LEFT JOIN incidents i ON ar.id = i.alert_rule_id
    AND i.triggered_at >= DATE_SUB(NOW(), INTERVAL sp.measurement_period_days DAY)
GROUP BY s.id, s.hostname, s.os_type, s.status, 
         t.name, sp.target_uptime_pct, sp.measurement_period_days
ORDER BY total_incidents DESC;
