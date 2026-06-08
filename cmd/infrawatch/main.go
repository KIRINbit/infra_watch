package main

import (
	"context"
	"infrawatch/internal/handlers"
	"infrawatch/internal/repository"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	// Строка подключения к MariaDB (пользователь root, пароль root123 из compose.yml)
	dsn := "root:root123@tcp(mariadb:3306)/infra_watch"

	log.Println("🔌 Подключение к MariaDB...")
	db, err := repository.NewMariaDB(dsn)
	if err != nil {
		log.Fatalf("❌ Не удалось подключиться к MariaDB: %v", err)
	}
	defer db.Close()
	log.Println("✅ Успешное подключение к MariaDB")

	// 1. Инициализация репозитория MariaDB
	serverRepo := repository.NewServerRepository(db)

	// 2. Инициализация репозитория InfluxDB
	influxURL := "http://influxdb:8086"
	influxToken := "YvR1y3o9inHq1ug_nOpyw2qqMThvcRVCNwnKMttaHOW7i11hP3nfo966Y7HkdOOWYLki2HXHJf7mHxRrdzCNbg=="
	influxOrg := "InfraWatch_Org"

	metricRepo := repository.NewInfluxRepository(influxURL, influxToken, influxOrg)

	// 3. Инициализация хендлера (передаем оба репозитория по паттерну Dependency Injection)
	serverHandler := handlers.NewServerHandler(serverRepo, metricRepo)

	// Настройка роутера Chi
	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// Раздача статики (если появится)
	fs := http.FileServer(http.Dir("static"))
	r.Handle("/static/*", http.StripPrefix("/static/", fs))

	// --- Страницы (GET) ---
	r.Get("/", serverHandler.RenderPage)
	r.Get("/panel", serverHandler.RenderPage)
	r.Get("/servers", serverHandler.RenderPage)
	r.Get("/incidents", serverHandler.RenderPage)
	r.Get("/alerts", serverHandler.RenderPage)
	r.Get("/reports", serverHandler.RenderPage)
	r.Get("/settings", serverHandler.RenderPage)

	// --- Действия над серверами ---
	r.Post("/servers/add", serverHandler.AddServer)
	r.Post("/servers/edit/{id}", serverHandler.EditServer)
	r.Post("/servers/delete/{id}", serverHandler.DeleteServer)

	// --- Действия над инцидентами ---
	r.Post("/incidents/ack/{id}", serverHandler.AcknowledgeIncident)
	r.Post("/incidents/resolve/{id}", serverHandler.ResolveIncident)

	// --- Действия над правилами алертов ---
	r.Post("/alerts/thresholds/{id}", serverHandler.UpdateAlertRule)
	r.Post("/alerts/toggle/{id}", serverHandler.ToggleAlertRule)

	// --- Действия над системными настройками ---
	r.Post("/settings/update/{id}", serverHandler.UpdateSystemSetting)

	// --- Экспорт отчётов ---
	r.Get("/reports/export.csv", serverHandler.ExportReportsCSV)

	// Настройка плавного завершения сервера (Graceful Shutdown)
	srv := &http.Server{
		Addr:    ":8080",
		Handler: r,
	}

	go func() {
		log.Println("🚀 Сервер запущен на http://localhost:8080")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Ошибка сервера: %v", err)
		}
	}()

	// Ожидание сигналов ОС для корректного закрытия
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("🛑 Завершение работы сервера...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Сервер принудительно остановлен: %v", err)
	}
	log.Println("👋 Сервер успешно остановлен")
}
