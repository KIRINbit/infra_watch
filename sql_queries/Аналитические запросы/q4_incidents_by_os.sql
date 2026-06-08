SELECT s.os_type,
       COUNT(DISTINCT s.id) AS server_count,
       COUNT(i.id) AS total_incidents,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE,
                               i.triggered_at,
                               COALESCE(i.resolved_at, NOW()))), 1) AS avg_resolution_min
FROM servers s
LEFT JOIN server_services ss ON s.id = ss.server_id
LEFT JOIN alert_rules ar     ON ss.id = ar.server_service_id
LEFT JOIN incidents i        ON ar.id = i.alert_rule_id
GROUP BY s.os_type
ORDER BY total_incidents DESC;
