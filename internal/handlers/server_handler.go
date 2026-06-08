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

	funcMap := template.FuncMap{
  	"split": strings.Split,
	}
	tmpl, err := template.New("index.html").Funcs(funcMap).ParseFiles("templates/index.html")
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
		// Если передали ?edit=<id>, добавляем сервер для редактирования
		if editIDStr := r.URL.Query().Get("edit"); editIDStr != "" {
			if id, err := strconv.Atoi(editIDStr); err == nil {
				if srv, err := h.serverRepo.GetByID(id); err == nil && srv != nil {
					data["EditServer"] = srv
				}
			}
		}
		// Сообщение об успехе/ошибке
		data["Flash"] = r.URL.Query().Get("msg")
	case "/incidents":
		incidents, err := h.serverRepo.GetActiveIncidents()
		if err != nil {
			log.Printf("Ошибка вьюхи инцидентов: %v", err)
		}
		data["Incidents"] = incidents
		data["Flash"] = r.URL.Query().Get("msg")
	case "/alerts":
		alertRules, err := h.serverRepo.GetAlertRules()
		if err != nil {
			log.Printf("Ошибка правил алертов: %v", err)
		}
		data["AlertRules"] = alertRules
		data["Flash"] = r.URL.Query().Get("msg")
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
		data["Flash"] = r.URL.Query().Get("msg")
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_ = tmpl.Execute(w, data)
}

// Постовые методы CRUD (Add/Edit/Delete) оставляем без изменений, но возвращаем на нужные вкладки
func (h *ServerHandler) AddServer(w http.ResponseWriter, r *http.Request) {
	teamID, _ := strconv.Atoi(r.FormValue("team_id"))
	server := &models.Server{
		Hostname: r.FormValue("hostname"),
		IP:       r.FormValue("ip_address"),
		OSType:   r.FormValue("os_type"),
		Status:   r.FormValue("status"),
		TeamID:   teamID,
	}
	msg := "added=1"
	if err := h.serverRepo.Create(server); err != nil {
		log.Printf("Ошибка добавления сервера: %v", err)
		msg = "error=add"
	}
	http.Redirect(w, r, "/servers?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) EditServer(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	teamID, _ := strconv.Atoi(r.FormValue("team_id"))
	server := &models.Server{
		ID:       id,
		Hostname: r.FormValue("hostname"),
		IP:       r.FormValue("ip_address"),
		OSType:   r.FormValue("os_type"),
		Status:   r.FormValue("status"),
		TeamID:   teamID,
	}
	msg := "updated=1"
	if err := h.serverRepo.Update(server); err != nil {
		log.Printf("Ошибка обновления сервера %d: %v", id, err)
		msg = "error=update"
	}
	http.Redirect(w, r, "/servers?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) DeleteServer(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	msg := "deleted=1"
	if err := h.serverRepo.Delete(id); err != nil {
		log.Printf("Ошибка удаления сервера %d: %v", id, err)
		msg = "error=delete"
	}
	http.Redirect(w, r, "/servers?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) AcknowledgeIncident(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/incidents?error=id", http.StatusSeeOther)
		return
	}

	msg := "ack=1"
	if err := h.serverRepo.AcknowledgeIncident(id); err != nil {
		log.Printf("Ошибка подтверждения инцидента %d: %v", id, err)
		msg = "error=ack"
	}
	http.Redirect(w, r, "/incidents?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) ResolveIncident(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/incidents?error=id", http.StatusSeeOther)
		return
	}

	msg := "resolved=1"
	if err := h.serverRepo.ResolveIncident(id); err != nil {
		log.Printf("Ошибка закрытия инцидента %d: %v", id, err)
		msg = "error=resolve"
	}
	http.Redirect(w, r, "/incidents?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) UpdateAlertRule(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/alerts?error=id", http.StatusSeeOther)
		return
	}

	minValue := strings.TrimSpace(r.FormValue("threshold_min"))
	maxValue := strings.TrimSpace(r.FormValue("threshold_max"))
	if !isDecimalOrEmpty(minValue) || !isDecimalOrEmpty(maxValue) {
		log.Printf("Некорректные пороги алерта %d: min=%q max=%q", id, minValue, maxValue)
		http.Redirect(w, r, "/alerts?error=threshold", http.StatusSeeOther)
		return
	}

	msg := "thresholds=1"
	if err := h.serverRepo.UpdateAlertRuleThresholds(id, minValue, maxValue); err != nil {
		log.Printf("Ошибка обновления алерта %d: %v", id, err)
		msg = "error=thresholds"
	}
	http.Redirect(w, r, "/alerts?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) ToggleAlertRule(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/alerts?error=id", http.StatusSeeOther)
		return
	}

	active := r.FormValue("active") == "1"
	msg := "toggled=1"
	if err := h.serverRepo.SetAlertRuleActive(id, active); err != nil {
		log.Printf("Ошибка переключения алерта %d: %v", id, err)
		msg = "error=toggle"
	}
	http.Redirect(w, r, "/alerts?"+msg, http.StatusSeeOther)
}

func (h *ServerHandler) UpdateSystemSetting(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		http.Redirect(w, r, "/settings?error=id", http.StatusSeeOther)
		return
	}

	value := strings.TrimSpace(r.FormValue("setting_value"))
	msg := "updated=1"
	if err := h.serverRepo.UpdateSystemSetting(id, value); err != nil {
		log.Printf("Ошибка обновления настройки %d: %v", id, err)
		msg = "error=update"
	}
	http.Redirect(w, r, "/settings?"+msg, http.StatusSeeOther)
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
