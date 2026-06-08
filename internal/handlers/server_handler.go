package handlers

import (
	"encoding/csv"
	"github.com/go-chi/chi/v5"
	"html/template"
	"infrawatch/internal/models"
	"infrawatch/internal/repository"
	"log"
	"net/http"
	"strconv"
	"strings"
)

type ServerHandler struct {
	serverRepo repository.ServerRepository
	metricRepo repository.MetricRepository
}

func NewServerHandler(sr repository.ServerRepository, mr repository.MetricRepository) *ServerHandler {
	return &ServerHandler{serverRepo: sr, metricRepo: mr}
}

// Универсальный рендеринг страниц
func (h *ServerHandler) RenderPage(w http.ResponseWriter, r *http.Request) {
	// Определяем вкладку на основе URL path
	tab := r.URL.Path
	if tab == "/" {
		tab = "/panel"
	}

	tmpl, err := template.ParseFiles("templates/index.html")
	if err != nil {
		log.Printf("Ошибка шаблона: %v", err)
		http.Error(w, "Ошибка загрузки UI", http.StatusInternalServerError)
		return
	}

	// Сборная солянка данных для передачи в HTML
	data := map[string]interface{}{
		"Title":      "InfraWatch — Система мониторинга",
		"CurrentTab": tab,
	}

	// Загружаем только то, что нужно конкретной вкладке
	switch tab {
	case "/panel":
		servers, _ := h.serverRepo.GetAllForDisplay()
		metrics, _ := h.metricRepo.GetLastMetrics("infra_metrics")
		data["Servers"] = servers
		data["Metrics"] = metrics
	case "/servers":
		servers, _ := h.serverRepo.GetAllForDisplay()
		data["Servers"] = servers
	case "/incidents":
		incidents, err := h.serverRepo.GetActiveIncidents()
		if err != nil {
			log.Printf("Ошибка вьюхи инцидентов: %v", err)
		}
		data["Incidents"] = incidents
	case "/alerts":
		alertRules, err := h.serverRepo.GetAlertRules()
		if err != nil {
			log.Printf("Ошибка правил алертов: %v", err)
		}
		data["AlertRules"] = alertRules
	case "/reports":
		reports, err := h.serverRepo.GetSLAReports()
		if err != nil {
			log.Printf("Ошибка SLA-отчетов: %v", err)
		}
		data["SLAReports"] = reports
	case "/settings":
		settings, err := h.serverRepo.GetSystemSettings()
		if err != nil {
			log.Printf("Ошибка настроек системы: %v", err)
		}
		data["SystemSettings"] = settings
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_ = tmpl.Execute(w, data)
}

// Постовые методы CRUD (Add/Delete) оставляем без изменений, но возвращаем на нужные вкладки
func (h *ServerHandler) AddServer(w http.ResponseWriter, r *http.Request) {
	teamID, _ := strconv.Atoi(r.FormValue("team_id"))
	server := &models.Server{
		Hostname: r.FormValue("hostname"),
		IP:       r.FormValue("ip_address"),
		OSType:   r.FormValue("os_type"),
		Status:   r.FormValue("status"),
		TeamID:   teamID,
	}
	_ = h.serverRepo.Create(server)
	http.Redirect(w, r, "/servers", http.StatusSeeOther) // перенаправляем на вкладку серверов
}

func (h *ServerHandler) DeleteServer(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	_ = h.serverRepo.Delete(id)
	http.Redirect(w, r, "/servers", http.StatusSeeOther)
}

func (h *ServerHandler) AcknowledgeIncident(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/incidents", http.StatusSeeOther)
		return
	}

	if err := h.serverRepo.AcknowledgeIncident(id); err != nil {
		log.Printf("Ошибка подтверждения инцидента %d: %v", id, err)
	}
	http.Redirect(w, r, "/incidents", http.StatusSeeOther)
}

func (h *ServerHandler) ResolveIncident(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/incidents", http.StatusSeeOther)
		return
	}

	if err := h.serverRepo.ResolveIncident(id); err != nil {
		log.Printf("Ошибка закрытия инцидента %d: %v", id, err)
	}
	http.Redirect(w, r, "/incidents", http.StatusSeeOther)
}

func (h *ServerHandler) UpdateAlertRule(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/alerts", http.StatusSeeOther)
		return
	}

	minValue := strings.TrimSpace(r.FormValue("threshold_min"))
	maxValue := strings.TrimSpace(r.FormValue("threshold_max"))
	if !isDecimalOrEmpty(minValue) || !isDecimalOrEmpty(maxValue) {
		log.Printf("Некорректные пороги алерта %d: min=%q max=%q", id, minValue, maxValue)
		http.Redirect(w, r, "/alerts", http.StatusSeeOther)
		return
	}

	if err := h.serverRepo.UpdateAlertRuleThresholds(id, minValue, maxValue); err != nil {
		log.Printf("Ошибка обновления алерта %d: %v", id, err)
	}
	http.Redirect(w, r, "/alerts", http.StatusSeeOther)
}

func (h *ServerHandler) ToggleAlertRule(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/alerts", http.StatusSeeOther)
		return
	}

	active := r.FormValue("active") == "1"
	if err := h.serverRepo.SetAlertRuleActive(id, active); err != nil {
		log.Printf("Ошибка переключения алерта %d: %v", id, err)
	}
	http.Redirect(w, r, "/alerts", http.StatusSeeOther)
}

func (h *ServerHandler) UpdateSystemSetting(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/settings", http.StatusSeeOther)
		return
	}

	value := strings.TrimSpace(r.FormValue("setting_value"))
	if err := h.serverRepo.UpdateSystemSetting(id, value); err != nil {
		log.Printf("Ошибка обновления настройки %d: %v", id, err)
	}
	http.Redirect(w, r, "/settings", http.StatusSeeOther)
}

func (h *ServerHandler) ExportReportsCSV(w http.ResponseWriter, r *http.Request) {
	reports, err := h.serverRepo.GetSLAReports()
	if err != nil {
		log.Printf("Ошибка экспорта SLA-отчетов: %v", err)
		http.Error(w, "Ошибка экспорта SLA-отчетов", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", `attachment; filename="sla_report.csv"`)

	writer := csv.NewWriter(w)
	defer writer.Flush()

	_ = writer.Write([]string{
		"server_id",
		"hostname",
		"os_type",
		"server_status",
		"team_name",
		"target_uptime_pct",
		"actual_uptime_pct",
		"measurement_period_days",
		"total_incidents",
		"critical_incidents",
		"total_downtime_minutes",
		"compliance_status",
	})

	for _, report := range reports {
		_ = writer.Write([]string{
			strconv.Itoa(report.ServerID),
			report.Hostname,
			report.OSType,
			report.ServerStatus,
			report.TeamName,
			report.TargetUptimePct,
			report.ActualUptimePct,
			strconv.Itoa(report.MeasurementPeriodDays),
			strconv.Itoa(report.TotalIncidents),
			strconv.Itoa(report.CriticalIncidents),
			strconv.Itoa(report.TotalDowntimeMinutes),
			report.ComplianceStatus,
		})
	}
}

func isDecimalOrEmpty(value string) bool {
	if value == "" {
		return true
	}
	_, err := strconv.ParseFloat(value, 64)
	return err == nil
}
