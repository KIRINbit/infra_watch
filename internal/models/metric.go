package models

import "time"

// ServerMetric представляет одну точку метрики из InfluxDB
type ServerMetric struct {
	Timestamp  time.Time `json:"timestamp"`
	Hostname   string    `json:"hostname"`
	MetricName string    `json:"metric_name"` // e.g., "cpu_usage", "ram_usage"
	Value      float64   `json:"value"`
}
