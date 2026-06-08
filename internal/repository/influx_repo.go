package repository

import (
	"context"
	"fmt"
	"infrawatch/internal/models"

	influxdb2 "github.com/influxdata/influxdb-client-go/v2"
)

type MetricRepository interface {
	GetLastMetrics(bucket string) ([]models.ServerMetric, error)
}

type influxMetricRepository struct {
	client influxdb2.Client
	org    string
}

// NewInfluxRepository создает клиент подключения к InfluxDB v2
func NewInfluxRepository(url, token, org string) MetricRepository {
	client := influxdb2.NewClient(url, token)
	return &influxMetricRepository{
		client: client,
		org:    org,
	}
}

// GetLastMetrics вытягивает последние записи из InfluxDB с помощью Flux
func (r *influxMetricRepository) GetLastMetrics(bucket string) ([]models.ServerMetric, error) {
	queryAPI := r.client.QueryAPI(r.org)

	// Flux-запрос: берем данные за последний час, фильтруем по измерению и берем последнее значение
	fluxQuery := fmt.Sprintf(`
		from(bucket: "%s")
			|> range(start: -1h)
			|> filter(fn: (r) => r["_measurement"] == "server_metrics")
			|> last()`, bucket)

	result, err := queryAPI.Query(context.Background(), fluxQuery)
	if err != nil {
		return nil, fmt.Errorf("ошибка выполнения Flux-запроса: %w", err)
	}
	defer result.Close()

	var metrics []models.ServerMetric

	// Читаем результаты построчно
	for result.Next() {
		record := result.Record()
		
		// ИСПРАВЛЕНО: ищем тег "hostname", как в Bash-скрипте, а не "host"
		hostname, _ := record.ValueByKey("hostname").(string)
		metricName := record.Field()
		
		var val float64
		if floatVal, ok := record.Value().(float64); ok {
			val = floatVal
		} else if intVal, ok := record.Value().(int64); ok {
			val = float64(intVal)
		}

		metrics = append(metrics, models.ServerMetric{
			Timestamp:  record.Time(),
			Hostname:   hostname,
			MetricName: metricName,
			Value:      val,
		})
	}

	if result.Err() != nil {
		return nil, fmt.Errorf("ошибка при чтении строк InfluxDB: %w", result.Err())
	}

	return metrics, nil
}
