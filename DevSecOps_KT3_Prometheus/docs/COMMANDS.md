# КТ-3: команды установки и проверки Prometheus 2.53.2

**Исполнитель:** Алакберова Симран Ахлиман, группа 4П1.23.

Ниже приведена последовательность команд, соответствующая учебному заданию. Для автоматической установки используйте `scripts/install_prometheus.sh` либо `ansible/prometheus_install.yml` из проекта.

## 1. Обновление apt, группа, пользователь и каталоги

```bash
sudo apt update
sudo apt install curl tar ca-certificates -y
sudo groupadd --system prometheus
sudo useradd --system --no-create-home --shell /usr/sbin/nologin --gid prometheus prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown root:root /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
sudo chmod 0750 /var/lib/prometheus
```

При повторном ручном запуске `groupadd` и `useradd` могут сообщить, что группа или пользователь уже существуют. Bash-скрипт из проекта учитывает этот случай.

## 2. Загрузка и распаковка архива

```bash
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.53.2/prometheus-2.53.2.linux-amd64.tar.gz
sha256sum prometheus-2.53.2.linux-amd64.tar.gz
tar -zxvf prometheus-2.53.2.linux-amd64.tar.gz
cd prometheus-2.53.2.linux-amd64
```

Сравните SHA256 с контрольной суммой **того же архива** на официальной странице релиза. Только совпадение с проверенным источником считается успешной проверкой целостности.

## 3. Копирование бинарных файлов и настроек

```bash
sudo install -o root -g root -m 0755 prometheus /usr/local/bin/prometheus
sudo install -o root -g root -m 0755 promtool /usr/local/bin/promtool
sudo cp -a consoles /etc/prometheus/
sudo cp -a console_libraries /etc/prometheus/
sudo chown -R root:root /etc/prometheus
```

Для сохранения настроек проекта из папки репозитория отдельно выполните:

```bash
sudo install -o root -g root -m 0644 configs/prometheus.yml /etc/prometheus/prometheus.yml
sudo promtool check config /etc/prometheus/prometheus.yml
```

Последние две команды выполняются из корня папки `DevSecOps_KT3_Prometheus` (сначала `cd` обратно в эту папку).

## 4. Создание systemd unit и запуск

```bash
sudo install -o root -g root -m 0644 systemd/prometheus.service /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status prometheus --no-pager
```

Их выполняют из корня папки проекта. Альтернативно файл можно создать через `sudo nano /etc/systemd/system/prometheus.service` и вставить содержимое из `systemd/prometheus.service`.

## 5. Настройка файрвола и проверка

```bash
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw allow from 192.168.56.0/24 to any port 9090 proto tcp
sudo ufw status
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS 'http://127.0.0.1:9090/api/v1/query?query=up'
```

Замените подсеть на вашу. Если UFW пока не активен, проверьте SSH-правило и только затем выполните `sudo ufw enable` в безопасной лабораторной среде. Для воспроизведения оригинального задания в изолированной лабораторной сети допускается `sudo ufw allow 9090/tcp`. Не публикуйте незащищенный интерфейс Prometheus в интернете.

## 6. Проверка через браузер

Откройте `http://IP_СЕРВЕРА:9090` и выполните PromQL-запрос `up{job="prometheus"}`. Через 15-30 секунд после запуска ожидаемое значение равно `1`.

## 7. Устранение ошибок

```bash
# Служба не работает
sudo journalctl -u prometheus -n 70 --no-pager
# Проверить конфигурацию
sudo promtool check config /etc/prometheus/prometheus.yml
# Проверить занятость порта
sudo ss -ltnp | grep ':9090'
# Проверить права на каталог данных
ls -ld /var/lib/prometheus
# Перезапуск службы
sudo systemctl restart prometheus
```
