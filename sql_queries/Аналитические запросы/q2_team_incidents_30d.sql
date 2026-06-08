SELECT t.name AS team_name,
       COUNT(i.id) AS incident_count,
       SUM(CASE WHEN i.severity = 'critical' THEN 1 ELSE 0 END) AS critical_cnt
FROM incidents i
JOIN alert_rules ar       ON i.alert_rule_id = ar.id
JOIN server_services ss   ON ar.server_service_id = ss.id
JOIN servers s            ON ss.server_id = s.id
JOIN teams t              ON s.team_id = t.id
WHERE i.triggered_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY t.id, t.name
HAVING incident_count > 0
ORDER BY critical_cnt DESC;
