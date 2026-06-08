package repository

import (
	"database/sql"
	"fmt"
	"infrawatch/internal/models"
)

type ServerRepository interface {
	Create(server *models.Server) error
	GetAllForDisplay() ([]models.ServerGridDisplay, error)
	GetByID(id int) (*models.Server, error)
	GetActiveIncidents() ([]models.Incident, error)
	GetAlertRules() ([]models.AlertRuleDisplay, error)
	GetSLAReports() ([]models.SLAReport, error)
	GetSystemSettings() ([]models.SystemSetting, error)
	AcknowledgeIncident(id int) error
	ResolveIncident(id int) error
	UpdateAlertRuleThresholds(id int, minValue, maxValue string) error
	SetAlertRuleActive(id int, active bool) error
	UpdateSystemSetting(id int, value string) error
	Update(server *models.Server) error
	Delete(id int) error
}

type mariaDBServerRepository struct {
	db *sql.DB
}

func NewServerRepository(db *sql.DB) ServerRepository {
	return &mariaDBServerRepository{db: db}
}

// Create — Добавление нового сервера (C)
func (r *mariaDBServerRepository) Create(s *models.Server) error {
	query := `INSERT INTO servers (hostname, ip_address, os_type, status, team_id) VALUES (?, ?, ?, ?, ?)`
	result, err := r.db.Exec(query, s.Hostname, s.IP, s.OSType, s.Status, s.TeamID)
	if err != nil {
		return fmt.Errorf("ошибка добавления сервера: %w", err)
	}

	id, err := result.LastInsertId()
	if err == nil {
		s.ID = int(id)
	}
	return nil
}

// GetAllForDisplay — Получение данных с JOIN (R). Выполняет требование №7
func (r *mariaDBServerRepository) GetAllForDisplay() ([]models.ServerGridDisplay, error) {
	query := `
		SELECT s.id, s.hostname, s.ip_address, s.os_type, s.status, t.name
		FROM servers s
		LEFT JOIN teams t ON s.team_id = t.id`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("ошибка получения списка серверов: %w", err)
	}
	defer rows.Close()

	var list []models.ServerGridDisplay
	for rows.Next() {
		var s models.ServerGridDisplay
		err := rows.Scan(&s.ID, &s.Hostname, &s.IP, &s.OSType, &s.Status, &s.TeamName)
		if err != nil {
			return nil, fmt.Errorf("ошибка сканирования строки: %w", err)
		}
		list = append(list, s)
	}
	return list, nil
}

// GetByID — Поиск сервера по ID
func (r *mariaDBServerRepository) GetByID(id int) (*models.Server, error) {
	query := `SELECT id, hostname, ip_address, os_type, status, team_id FROM servers WHERE id = ?`
	row := r.db.QueryRow(query, id)

	var s models.Server
	err := row.Scan(&s.ID, &s.Hostname, &s.IP, &s.OSType, &s.Status, &s.TeamID)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, fmt.Errorf("ошибка получения сервера по ID: %w", err)
	}
	return &s, nil
}

// Update — Редактирование сервера (U)
func (r *mariaDBServerRepository) Update(s *models.Server) error {
	query := `UPDATE servers SET hostname = ?, ip_address = ?, os_type = ?, status = ?, team_id = ? WHERE id = ?`
	_, err := r.db.Exec(query, s.Hostname, s.IP, s.OSType, s.Status, s.TeamID, s.ID)
	if err != nil {
		return fmt.Errorf("ошибка обновления сервера: %w", err)
	}
	return nil
}

// Delete — Удаление сервера (D)
func (r *mariaDBServerRepository) Delete(id int) error {
	query := `DELETE FROM servers WHERE id = ?`
	_, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("ошибка удаления сервера: %w", err)
	}
	return nil
}

func (r *mariaDBServerRepository) GetActiveIncidents() ([]models.Incident, error) {
	query := `
		SELECT
			i.id,
			s.hostname,
			COALESCE(i.description, ''),
			i.severity,
			i.status,
			DATE_FORMAT(i.triggered_at, '%Y-%m-%d %H:%i:%s')
		FROM incidents i
		JOIN alert_rules ar ON i.alert_rule_id = ar.id
		JOIN server_services ss ON ar.server_service_id = ss.id
		JOIN servers s ON ss.server_id = s.id
		WHERE i.status IN ('open', 'acknowledged')
		ORDER BY i.triggered_at DESC`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("ошибка получения активных инцидентов: %w", err)
	}
	defer rows.Close()

	var incidents []models.Incident
	for rows.Next() {
		var inc models.Incident
		err := rows.Scan(&inc.ID, &inc.Hostname, &inc.Description, &inc.Severity, &inc.Status, &inc.CreatedAt)
		if err != nil {
			return nil, err
		}
		incidents = append(incidents, inc)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("ошибка чтения активных инцидентов: %w", err)
	}

	return incidents, nil
}

func (r *mariaDBServerRepository) AcknowledgeIncident(id int) error {
	query := `UPDATE incidents SET status = 'acknowledged' WHERE id = ? AND status = 'open'`
	_, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("ошибка подтверждения инцидента: %w", err)
	}
	return nil
}

func (r *mariaDBServerRepository) ResolveIncident(id int) error {
	query := `
		UPDATE incidents
		SET status = 'resolved', resolved_at = COALESCE(resolved_at, NOW())
		WHERE id = ? AND status IN ('open', 'acknowledged')`
	_, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("ошибка закрытия инцидента: %w", err)
	}
	return nil
}

func (r *mariaDBServerRepository) GetAlertRules() ([]models.AlertRuleDisplay, error) {
	query := `
		SELECT
			ar.id,
			s.hostname,
			svc.name,
			svc.port,
			ar.metric_name,
			COALESCE(CAST(ar.threshold_min AS CHAR), ''),
			COALESCE(CAST(ar.threshold_max AS CHAR), ''),
			ar.is_active,
			ss.status,
			t.name
		FROM alert_rules ar
		JOIN server_services ss ON ar.server_service_id = ss.id
		JOIN servers s ON ss.server_id = s.id
		JOIN services svc ON ss.service_id = svc.id
		JOIN teams t ON s.team_id = t.id
		ORDER BY ar.is_active DESC, s.hostname, svc.name, ar.metric_name`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("ошибка получения правил алертов: %w", err)
	}
	defer rows.Close()

	var rules []models.AlertRuleDisplay
	for rows.Next() {
		var rule models.AlertRuleDisplay
		err := rows.Scan(
			&rule.ID,
			&rule.Hostname,
			&rule.ServiceName,
			&rule.ServicePort,
			&rule.MetricName,
			&rule.ThresholdMin,
			&rule.ThresholdMax,
			&rule.IsActive,
			&rule.ServiceStatus,
			&rule.TeamName,
		)
		if err != nil {
			return nil, fmt.Errorf("ошибка сканирования правила алерта: %w", err)
		}
		rules = append(rules, rule)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("ошибка чтения правил алертов: %w", err)
	}

	return rules, nil
}

func (r *mariaDBServerRepository) GetSLAReports() ([]models.SLAReport, error) {
	query := `
		SELECT
			report.server_id,
			report.hostname,
			report.os_type,
			report.server_status,
			report.team_name,
			COALESCE(CAST(report.target_uptime_pct AS CHAR), '0.00'),
			COALESCE(report.measurement_period_days, 0),
			COALESCE(report.total_incidents, 0),
			COALESCE(report.critical_incidents, 0),
			COALESCE(report.total_downtime_minutes, 0),
			CAST(ROUND(report.actual_uptime_pct, 2) AS CHAR),
			CASE
				WHEN report.actual_uptime_pct >= COALESCE(report.target_uptime_pct, 0) THEN 'ok'
				WHEN COALESCE(report.critical_incidents, 0) > 0 THEN 'critical'
				ELSE 'warning'
			END
		FROM (
			SELECT
				server_id,
				hostname,
				os_type,
				server_status,
				team_name,
				target_uptime_pct,
				measurement_period_days,
				total_incidents,
				critical_incidents,
				total_downtime_minutes,
				CASE
					WHEN COALESCE(measurement_period_days, 0) = 0 THEN 0
					ELSE GREATEST(
						0,
						(
							(COALESCE(measurement_period_days, 0) * 24 * 60 - COALESCE(total_downtime_minutes, 0)) * 100.0
						) / (COALESCE(measurement_period_days, 0) * 24 * 60)
					)
				END AS actual_uptime_pct
			FROM v_server_sla_report
		) report
		ORDER BY report.actual_uptime_pct ASC, report.critical_incidents DESC, report.hostname`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("ошибка получения SLA-отчетов: %w", err)
	}
	defer rows.Close()

	var reports []models.SLAReport
	for rows.Next() {
		var report models.SLAReport
		err := rows.Scan(
			&report.ServerID,
			&report.Hostname,
			&report.OSType,
			&report.ServerStatus,
			&report.TeamName,
			&report.TargetUptimePct,
			&report.MeasurementPeriodDays,
			&report.TotalIncidents,
			&report.CriticalIncidents,
			&report.TotalDowntimeMinutes,
			&report.ActualUptimePct,
			&report.ComplianceStatus,
		)
		if err != nil {
			return nil, fmt.Errorf("ошибка сканирования SLA-отчета: %w", err)
		}
		reports = append(reports, report)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("ошибка чтения SLA-отчетов: %w", err)
	}

	return reports, nil
}

func (r *mariaDBServerRepository) GetSystemSettings() ([]models.SystemSetting, error) {
	query := `
		SELECT
			ss.id,
			ss.setting_key,
			COALESCE(ss.setting_value, ''),
			DATE_FORMAT(ss.updated_at, '%Y-%m-%d %H:%i:%s'),
			COALESCE(u.username, 'system')
		FROM system_settings ss
		LEFT JOIN users u ON ss.updated_by_user_id = u.id
		ORDER BY ss.setting_key`

	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("ошибка получения настроек системы: %w", err)
	}
	defer rows.Close()

	var settings []models.SystemSetting
	for rows.Next() {
		var setting models.SystemSetting
		err := rows.Scan(
			&setting.ID,
			&setting.Key,
			&setting.Value,
			&setting.UpdatedAt,
			&setting.UpdatedBy,
		)
		if err != nil {
			return nil, fmt.Errorf("ошибка сканирования настройки системы: %w", err)
		}
		settings = append(settings, setting)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("ошибка чтения настроек системы: %w", err)
	}

	return settings, nil
}

func (r *mariaDBServerRepository) UpdateAlertRuleThresholds(id int, minValue, maxValue string) error {
	query := `
		UPDATE alert_rules
		SET threshold_min = NULLIF(?, ''), threshold_max = NULLIF(?, '')
		WHERE id = ?`
	_, err := r.db.Exec(query, minValue, maxValue, id)
	if err != nil {
		return fmt.Errorf("ошибка обновления порогов алерта: %w", err)
	}
	return nil
}

func (r *mariaDBServerRepository) SetAlertRuleActive(id int, active bool) error {
	query := `UPDATE alert_rules SET is_active = ? WHERE id = ?`
	_, err := r.db.Exec(query, active, id)
	if err != nil {
		return fmt.Errorf("ошибка изменения активности алерта: %w", err)
	}
	return nil
}

func (r *mariaDBServerRepository) UpdateSystemSetting(id int, value string) error {
	query := `
		UPDATE system_settings
		SET setting_value = ?, updated_by_user_id = 1
		WHERE id = ?`
	_, err := r.db.Exec(query, value, id)
	if err != nil {
		return fmt.Errorf("ошибка обновления настройки системы: %w", err)
	}
	return nil
}
