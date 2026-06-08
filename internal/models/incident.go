package models

// Incident представляет запись из представления v_active_incidents_full
type Incident struct {
	ID          int    `json:"id"`
	Hostname    string `json:"hostname"`
	Description string `json:"description"`
	Severity    string `json:"severity"`
	Status      string `json:"status"`
	CreatedAt   string `json:"created_at"`
}
