#!/usr/bin/env bash
# КТ-3. Установка Prometheus 2.53.2 на Ubuntu/Debian Linux amd64.
# Запуск: sudo bash scripts/install_prometheus.sh
# Дополнительно: PROMETHEUS_SHA256=<64-символьный хеш> sudo -E bash scripts/install_prometheus.sh
set -Eeuo pipefail

VERSION="2.53.2"
ARCHIVE="prometheus-${VERSION}.linux-amd64.tar.gz"
RELEASE_DIR="prometheus-${VERSION}.linux-amd64"
DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v${VERSION}/${ARCHIVE}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Ошибка: запустите скрипт через sudo." >&2
  exit 1
fi
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Ошибка: скрипт рассчитан на Linux amd64 (x86_64)." >&2
  exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Ошибка: нужна Ubuntu или Debian с apt-get." >&2
  exit 1
fi

# 1. Обновление индексов пакетов и установка необходимых утилит.
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl tar

# 2. Отдельная системная группа и непривилегированный пользователь.
getent group prometheus >/dev/null || groupadd --system prometheus
id -u prometheus >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin --gid prometheus prometheus

# 3. Настройки доступны только для изменения root, данные записывает Prometheus.
install -d -o root -g root -m 0755 /etc/prometheus
install -d -o prometheus -g prometheus -m 0750 /var/lib/prometheus

# 4. Скачивание официального архива. Не отключать HTTPS-проверки.
WORK_DIR="$(mktemp -d /tmp/prometheus-kt3.XXXXXX)"
trap 'rm -rf "${WORK_DIR}"' EXIT
curl --fail --location --show-error --silent --retry 3 \
  --output "${WORK_DIR}/${ARCHIVE}" "${DOWNLOAD_URL}"

# 5. Рекомендуемая проверка целостности по SHA256 с официальной страницы.
if [[ -n "${PROMETHEUS_SHA256:-}" ]]; then
  if [[ ! "${PROMETHEUS_SHA256}" =~ ^[a-fA-F0-9]{64}$ ]]; then
    echo "Ошибка: PROMETHEUS_SHA256 должен содержать 64 шестнадцатеричных символа." >&2
    exit 1
  fi
  printf '%s  %s\n' "${PROMETHEUS_SHA256}" "${WORK_DIR}/${ARCHIVE}" | sha256sum --check --status
  echo "SHA256: архив совпадает с указанной контрольной суммой."
else
  echo "ВНИМАНИЕ: SHA256 не сверялся. Сравните вывод с хешем из официального релиза:"
  sha256sum "${WORK_DIR}/${ARCHIVE}"
fi

# 6. Распаковка и копирование бинарных файлов.
tar -xzf "${WORK_DIR}/${ARCHIVE}" -C "${WORK_DIR}"
SOURCE_DIR="${WORK_DIR}/${RELEASE_DIR}"
install -o root -g root -m 0755 "${SOURCE_DIR}/prometheus" /usr/local/bin/prometheus
install -o root -g root -m 0755 "${SOURCE_DIR}/promtool" /usr/local/bin/promtool

# 7. Файлы веб-консолей и конфигурация.
cp -a "${SOURCE_DIR}/consoles" /etc/prometheus/
cp -a "${SOURCE_DIR}/console_libraries" /etc/prometheus/
chown -R root:root /etc/prometheus/consoles /etc/prometheus/console_libraries
install -o root -g root -m 0644 "${PROJECT_DIR}/configs/prometheus.yml" /etc/prometheus/prometheus.yml

# 8. Проверка YAML-конфигурации до запуска.
/usr/local/bin/promtool check config /etc/prometheus/prometheus.yml

# 9. Установка и запуск службы systemd.
install -o root -g root -m 0644 "${PROJECT_DIR}/systemd/prometheus.service" /etc/systemd/system/prometheus.service
systemctl daemon-reload
systemctl enable --now prometheus
systemctl restart prometheus

# 10. Краткий результат установки. UFW не меняется автоматически.
/usr/local/bin/prometheus --version | head -n 1
systemctl --no-pager --full status prometheus || true
printf '\nГотово. Проверка: sudo bash scripts/verify_prometheus.sh\n'
printf 'Порт 9090 не открывается автоматически в UFW. См. README.md.\n'
