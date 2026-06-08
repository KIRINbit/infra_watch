package models

type AlertRuleDisplay struct {
	ID            int    `json:"id"`
	Hostname      string `json:"hostname"`
	ServiceName   string `json:"service_name"`
	ServicePort   int    `json:"service_port"`
	MetricName    string `json:"metric_name"`
	ThresholdMin  string `json:"threshold_min"`
	ThresholdMax  string `json:"threshold_max"`
	IsActive      bool   `json:"is_active"`
	ServiceStatus string `json:"service_status"`
	TeamName      string `json:"team_name"`
}
