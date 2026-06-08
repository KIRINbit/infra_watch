package models

type Team struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type Server struct {
	ID       int    `json:"id"`
	Hostname string `json:"hostname"`
	IP       string `json:"ip"`
	OSType   string `json:"os_type"`
	Status   string `json:"status"`
	TeamID   int    `json:"team_id"`
}

type ServerGridDisplay struct {
	ID       int    `json:"id"`
	Hostname string `json:"hostname"`
	IP       string `json:"ip"`
	OSType   string `json:"os_type"`
	Status   string `json:"status"`
	TeamName string `json:"team_name"`
}
