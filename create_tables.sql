CREATE DATABASE IF NOT EXISTS infra_watch 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE infra_watch;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'engineer', 'viewer') NOT NULL DEFAULT 'viewer',
    email VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE teams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    lead_user_id INT NOT NULL,
    FOREIGN KEY (lead_user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE TABLE servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    os_type VARCHAR(50),
    location VARCHAR(100),
    status ENUM('online', 'offline', 'maintenance') DEFAULT 'online',
    team_id INT NOT NULL,
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE RESTRICT
);

CREATE TABLE services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    port INT NOT NULL,
    protocol VARCHAR(20) DEFAULT 'TCP',
    description TEXT
);

CREATE TABLE server_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    server_id INT NOT NULL,
    service_id INT NOT NULL,
    status ENUM('up', 'down', 'degraded') DEFAULT 'up',
    last_checked TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
    UNIQUE KEY uk_server_service (server_id, service_id)
);

CREATE TABLE alert_rules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    server_service_id INT NOT NULL,
    metric_name VARCHAR(50) NOT NULL,
    threshold_min DECIMAL(8,2),
    threshold_max DECIMAL(8,2),
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (server_service_id) REFERENCES server_services(id) ON DELETE CASCADE
);

CREATE TABLE incidents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alert_rule_id INT NOT NULL,
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    status ENUM('open', 'acknowledged', 'resolved') DEFAULT 'open',
    description TEXT,
    FOREIGN KEY (alert_rule_id) REFERENCES alert_rules(id) ON DELETE CASCADE
);

CREATE TABLE maintenance_windows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    server_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    reason VARCHAR(255),
    created_by_user_id INT NOT NULL,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CHECK (end_time > start_time)
);

CREATE TABLE sla_policies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    team_id INT NOT NULL,
    target_uptime_pct DECIMAL(5,2) NOT NULL CHECK (target_uptime_pct BETWEEN 0 AND 100),
    measurement_period_days INT NOT NULL DEFAULT 30,
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
);

CREATE TABLE system_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by_user_id INT,
    FOREIGN KEY (updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);
