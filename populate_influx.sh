#!/bin/bash
TOKEN="YvR1y3o9inHq1ug_nOpyw2qqMThvcRVCNwnKMttaHOW7i11hP3nfo966Y7HkdOOWYLki2HXHJf7mHxRrdzCNbg=="
ORG="InfraWatch_Org"
BUCKET="infra_metrics"

echo "Запись метрик server_metrics..."
for i in {1..12}; do
  CPU=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*100}')
  RAM=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*100}')
  DISK=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*100}')
  NET_IN=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*50}')
  NET_OUT=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*30}')

  LINE="server_metrics,server_id=1,hostname=srv-web-01,os_type=Ubuntu\ 22.04,env=prod cpu_usage_pct=$CPU,ram_usage_pct=$RAM,disk_usage_pct=$DISK,net_in_mbps=$NET_IN,net_out_mbps=$NET_OUT"

  curl -s -XPOST "http://localhost:8086/api/v2/write?org=$ORG&bucket=$BUCKET&precision=ns" \
    --header "Authorization: Token $TOKEN" \
    --data-raw "$LINE"

  echo "  Точка $i записана"
  sleep 1
done

echo ""
echo "Запись метрик service_metrics..."
for i in {1..12}; do
  RESPONSE_TIME=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*400+100}')
  STATUS_CODE=$((200 + RANDOM % 3))
  REQUESTS_PER_SEC=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf "%.1f", rand()*45+5}')

  LINE="service_metrics,service_id=5,server_id=1,protocol=HTTP response_time_ms=$RESPONSE_TIME,status_code=$STATUS_CODE,requests_per_sec=$REQUESTS_PER_SEC"

  curl -s -XPOST "http://localhost:8086/api/v2/write?org=$ORG&bucket=$BUCKET&precision=ns" \
    --header "Authorization: Token $TOKEN" \
    --data-raw "$LINE"

  echo "  Точка $i записана"
  sleep 1
done

echo "Тестовые данные успешно записаны"
