-- ========================================
-- Хранимые процедуры и функции InfraWatch
-- ========================================

-- Процедура 1: Завершение инцидента
DROP PROCEDURE IF EXISTS resolve_incident;
DELIMITER $$
CREATE PROCEDURE resolve_incident(
    IN p_incident_id INT,
    IN p_resolved_by_user_id INT,
    OUT p_duration_minutes INT
)
BEGIN
    DECLARE v_triggered_at DATETIME;
    DECLARE v_current_status VARCHAR(20);

    SELECT triggered_at, status INTO v_triggered_at, v_current_status
    FROM incidents WHERE id = p_incident_id;

    IF v_triggered_at IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Инцидент не найден';
    END IF;

    IF v_current_status = 'resolved' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Инцидент уже закрыт';
    END IF;

    UPDATE incidents
    SET status = 'resolved', resolved_at = NOW()
    WHERE id = p_incident_id;

    SET p_duration_minutes = TIMESTAMPDIFF(MINUTE, v_triggered_at, NOW());
END$$
DELIMITER ;

-- Процедура 2: Планирование окна обслуживания
DROP PROCEDURE IF EXISTS schedule_maintenance;
DELIMITER $$
CREATE PROCEDURE schedule_maintenance(
    IN p_server_id INT,
    IN p_start_time DATETIME,
    IN p_end_time DATETIME,
    IN p_reason VARCHAR(255),
    IN p_user_id INT
)
BEGIN
    DECLARE v_server_exists INT DEFAULT 0;

    IF p_end_time <= p_start_time THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Время окончания должно быть позже начала';
    END IF;

    SELECT COUNT(*) INTO v_server_exists FROM servers WHERE id = p_server_id;
    IF v_server_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сервер не найден';
    END IF;

    INSERT INTO maintenance_windows (server_id, start_time, end_time, reason, created_by_user_id)
    VALUES (p_server_id, p_start_time, p_end_time, p_reason, p_user_id);

    UPDATE servers SET status = 'maintenance' WHERE id = p_server_id;
END$$
DELIMITER ;

-- Функция 1: Длительность инцидента в минутах
DROP FUNCTION IF EXISTS get_incident_duration_minutes;
DELIMITER $$
CREATE FUNCTION get_incident_duration_minutes(p_incident_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_triggered DATETIME;
    DECLARE v_resolved DATETIME;

    SELECT triggered_at, resolved_at INTO v_triggered, v_resolved
    FROM incidents WHERE id = p_incident_id;

    IF v_triggered IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN TIMESTAMPDIFF(MINUTE, v_triggered, COALESCE(v_resolved, NOW()));
END$$
DELIMITER ;

-- Функция 2: Процент доступности сервера за период
DROP FUNCTION IF EXISTS calculate_uptime_percentage;
DELIMITER $$
CREATE FUNCTION calculate_uptime_percentage(
    p_server_id INT,
    p_period_days INT
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_downtime_minutes INT DEFAULT 0;
    DECLARE v_total_minutes INT;
    DECLARE v_period_start DATETIME;

    SET v_period_start = DATE_SUB(NOW(), INTERVAL p_period_days DAY);
    SET v_total_minutes = p_period_days * 24 * 60;

    SELECT COALESCE(SUM(
        TIMESTAMPDIFF(MINUTE,
            GREATEST(i.triggered_at, v_period_start),
            COALESCE(i.resolved_at, NOW())
        )
    ), 0)
    INTO v_downtime_minutes
    FROM incidents i
    JOIN alert_rules ar ON i.alert_rule_id = ar.id
    JOIN server_services ss ON ar.server_service_id = ss.id
    WHERE ss.server_id = p_server_id
      AND i.triggered_at >= v_period_start;

    IF v_downtime_minutes >= v_total_minutes THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(((v_total_minutes - v_downtime_minutes) / v_total_minutes) * 100, 2);
END$$
DELIMITER ;
