SELECT s.hostname,
       svc.name AS service_name,
       ar.metric_name,
       ar.threshold_min,
       ar.threshold_max,
       i.severity,
       i.status
FROM alert_rules ar
JOIN server_services ss ON ar.server_service_id = ss.id
JOIN servers s          ON ss.server_id = s.id
JOIN services svc       ON ss.service_id = svc.id
JOIN incidents i        ON ar.id = i.alert_rule_id
WHERE ar.is_active = TRUE
  AND i.status IN ('open', 'acknowledged')
ORDER BY i.triggered_at DESC;
