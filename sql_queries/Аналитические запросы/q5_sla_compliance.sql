SELECT t.name,
       sp.target_uptime_pct,
       COUNT(i.id) AS incidents_in_period,
       sp.measurement_period_days
FROM teams t
JOIN sla_policies sp ON t.id = sp.team_id
JOIN servers s       ON t.id = s.team_id
LEFT JOIN server_services ss ON s.id = ss.server_id
LEFT JOIN alert_rules ar     ON ss.id = ar.server_service_id
LEFT JOIN incidents i        ON ar.id = i.alert_rule_id
                            AND i.triggered_at >= DATE_SUB(NOW(),
                                 INTERVAL sp.measurement_period_days DAY)
GROUP BY t.id, t.name, sp.target_uptime_pct, sp.measurement_period_days;
