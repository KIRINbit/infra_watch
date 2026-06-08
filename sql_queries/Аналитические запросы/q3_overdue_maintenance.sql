SELECT s.hostname,
       s.ip_address,
       mw.end_time,
       mw.reason,
       u.username AS created_by
FROM maintenance_windows mw
JOIN servers s ON mw.server_id = s.id
JOIN users u   ON mw.created_by_user_id = u.id
WHERE mw.end_time < NOW()
  AND s.status = 'maintenance'
ORDER BY mw.end_time ASC;
