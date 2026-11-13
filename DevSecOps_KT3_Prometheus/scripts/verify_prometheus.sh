#!/usr/bin/env bash
# КТ-3. Проверка установки, systemd, порта и PromQL up.
set -Eeuo pipefail

echo '[1/6] Проверка исполняемого файла'
/usr/local/bin/prometheus --version | head -n 1

echo '[2/6] Проверка файла конфигурации'
/usr/local/bin/promtool check config /etc/prometheus/prometheus.yml

echo '[3/6] Проверка службы systemd'
systemctl is-enabled prometheus
systemctl is-active prometheus

echo '[4/6] Проверка готовности (HTTP 200)'
curl --fail --show-error --silent http://127.0.0.1:9090/-/ready
printf '\n'

echo '[5/6] Проверка эндпоинта /metrics'
METRICS="$(curl --fail --show-error --silent http://127.0.0.1:9090/metrics)"
grep -m 1 '^prometheus_build_info{' <<< "${METRICS}" || { echo 'Метрика prometheus_build_info не найдена.' >&2; exit 1; }

echo '[6/6] Проверка запроса up{job="prometheus"}'
response="$(curl --fail --show-error --silent --get \
  --data-urlencode 'query=up{job="prometheus"}' \
  'http://127.0.0.1:9090/api/v1/query')"
python3 -c 'import json,sys; r=json.loads(sys.argv[1]); v=r.get("data",{}).get("result",[]); print(json.dumps(v,ensure_ascii=False,indent=2)); sys.exit(0 if any(x.get("value",[None,None])[1]=="1" for x in v) else 1)' "${response}" || {
 echo 'Метрика up пока недоступна или не равна 1. Подождите 15-30 секунд и повторите проверку.' >&2
 exit 1
}
echo 'Все проверки завершены успешно.'
