package models

type SLAReport struct {
	ServerID              int    `json:"server_id"`
	Hostname              string `json:"hostname"`
	OSType                string `json:"os_type"`
	ServerStatus          string `json:"server_status"`
	TeamName              string `json:"team_name"`
	TargetUptimePct       string `json:"target_uptime_pct"`
	MeasurementPeriodDays int    `json:"measurement_period_days"`
	TotalIncidents        int    `json:"total_incidents"`
	CriticalIncidents     int    `json:"critical_incidents"`
	TotalDowntimeMinutes  int    `json:"total_downtime_minutes"`
	ActualUptimePct       string `json:"actual_uptime_pct"`
	ComplianceStatus      string `json:"compliance_status"`
}
