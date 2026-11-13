# КТ-3 по DevSecOps: установка и настройка Prometheus

**Выполнила:** Алакберова Симран Ахлиман  
**Группа:** 4П1.23  
**Дисциплина:** DevSecOps  
**Тема:** Установка Prometheus 2.53.2 на Ubuntu Server, создание службы systemd, настройка порта 9090 и проверка веб-интерфейса.

## Цель работы

Установить систему мониторинга Prometheus, настроить безопасную работу от отдельного системного пользователя, сбор собственных метрик, управление службой через systemd и доступ к веб-интерфейсу по HTTP-порту 9090.

## Краткая теория

Prometheus собирает метрики по модели pull с HTTP-эндпоинтов `/metrics`. Данные сохраняются как временные ряды. Компоненты экосистемы: Prometheus Server, Exporters, Alertmanager и Pushgateway. В КТ-3 устанавливается только Prometheus Server. В `prometheus.yml` указан один target: `127.0.0.1:9090`, то есть система наблюдает за собой.

## Состав проекта

```text
DevSecOps_KT3_Prometheus/
├── README.md
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini
│   ├── prometheus_install.yml
│   ├── group_vars/prometheus.yml
│   └── templates/
│       ├── prometheus.yml.j2
│       └── prometheus.service.j2
├── configs/prometheus.yml
├── systemd/prometheus.service
├── scripts/
│   ├── install_prometheus.sh
│   └── verify_prometheus.sh
├── docs/COMMANDS.md
└── report/KT3_DevSecOps_Report.docx
```

## Требования

- Ubuntu Server 22.04 или 24.04 (либо совместимая Debian), архитектура x86_64 (amd64).
- Права `sudo` и доступ к GitHub Releases для скачивания официального архива.
- Для Ansible: SSH-доступ к виртуальной машине и установленный Ansible на управляющем узле.
- Проверенный доступ к порту 22/SSH до изменения правил UFW.

Версия **2.53.2** сохранена как в учебном задании. Она выпущена в 2024 году и не является актуальным выпуском на 2026 год. Для реальной эксплуатации используйте поддерживаемую версию после тестирования совместимости.

## Вариант 1. Установка одной командой с помощью Bash

На виртуальной машине Ubuntu скопируйте распакованную папку проекта, затем выполните:

```bash
cd DevSecOps_KT3_Prometheus
sudo bash scripts/install_prometheus.sh
sudo bash scripts/verify_prometheus.sh
```

Скрипт обновляет apt, создает пользователя и группу `prometheus`, папки `/etc/prometheus` и `/var/lib/prometheus`, скачивает и распаковывает архив, копирует `prometheus`, `promtool`, `consoles`, `console_libraries`, проверяет конфигурацию и запускает службу через systemd.

### Проверка архива по SHA256

Перед установкой желательно открыть [официальный релиз 2.53.2](https://github.com/prometheus/prometheus/releases/tag/v2.53.2) и скопировать SHA256 для файла `prometheus-2.53.2.linux-amd64.tar.gz`. Тогда:

```bash
sudo env PROMETHEUS_SHA256='ВСТАВЬТЕ_64_СИМВОЛА_ША256' bash scripts/install_prometheus.sh
```

Замените заглушку настоящим хешем. Если переменная не указана, скрипт показывает вычисленную сумму, но **не считает проверку подлинности выполненной**. Сравните сумму вручную с официальным источником. Не используйте произвольное значение вместо хеша.

## Вариант 2. Установка через Ansible

На управляющем хосте Ubuntu:

```bash
sudo apt update
sudo apt install ansible -y
```

В файле `ansible/inventory.ini` замените примерный IP `192.168.56.101` и пользователя `ubuntu` на параметры своей учебной ВМ. SSH-доступ должен работать до запуска Playbook. При желании укажите SHA256 архива в `ansible/group_vars/prometheus.yml`.

```bash
cd DevSecOps_KT3_Prometheus/ansible
ansible prometheus -m ping
ansible-playbook prometheus_install.yml --syntax-check
ansible-playbook prometheus_install.yml --ask-become-pass
```

Если вход по SSH настроен на пароль, добавьте `--ask-pass` и установите `sshpass` на управляющем узле. SSH-ключи предпочтительнее. Playbook выполняет те же действия, устанавливает unit и ожидает HTTP-ответ `200` от `/-/ready`.

## Проверка результата

На сервере:

```bash
prometheus --version
sudo promtool check config /etc/prometheus/prometheus.yml
systemctl is-enabled prometheus
systemctl is-active prometheus
sudo systemctl status prometheus --no-pager
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:9090/metrics | head
sudo ufw status
```

Ожидается: версия 2.53.2, конфигурация валидна, статус службы `active (running)`, `is-enabled: enabled`, HTTP-ответ готовности и текстовые метрики.

После запуска откройте `http://IP_СЕРВЕРА:9090` и выполните запрос **`up{job="prometheus"}`**. После первого сбора метрик должен появиться результат `1`.

## Настройка UFW и безопасность

Prometheus в учебном проекте слушает адрес `0.0.0.0:9090` для доступа через браузер с другой машины. Веб-интерфейс **не защищен логином по умолчанию**. Не открывайте порт в публичный интернет. Для виртуальной машины и доверенной подсети допускается:

```bash
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw allow from 192.168.56.0/24 to any port 9090 proto tcp
sudo ufw status
```

Замените `192.168.56.0/24` своей подсетью. Если `ufw status` показывает `inactive`, в лабораторной сети можно выполнить `sudo ufw enable` после проверки разрешающего правила для SSH. Включение UFW на удаленном сервере требует осторожности. Команда из условия `sudo ufw allow 9090/tcp` открывает порт для любого адреса: используйте ее **только в изолированной учебной сети**. Если нужен доступ через SSH-туннель без открытия порта, можно настроить `--web.listen-address=127.0.0.1:9090` и выполнить `ssh -L 9090:127.0.0.1:9090 user@IP_СЕРВЕРА`.

## Скриншоты для защиты

Рекомендуется приложить **собственные** скриншоты: (1) `prometheus --version`; (2) `systemctl status prometheus`; (3) `ufw status`; (4) страницу веб-интерфейса с запросом `up{job="prometheus"}` и значением `1`. Изображения, приведенные в условии задания, являются примерами, а не подтверждением запуска на вашей машине.

## Заключение

Созданы готовые конфигурация Prometheus, systemd unit, сценарий автоматической установки Bash и Playbook Ansible. Проект подготовлен к развёртыванию на учебной Ubuntu Server. Фактический запуск на удаленной ВМ и скриншоты с нее должны быть выполнены отдельно.

## Источники

- [Официальный релиз Prometheus 2.53.2](https://github.com/prometheus/prometheus/releases/tag/v2.53.2)
- [Первое знакомство с Prometheus](https://prometheus.io/docs/introduction/first_steps/)
- [Параметры запуска Prometheus](https://prometheus.io/docs/prometheus/latest/command-line/prometheus/)
- [Проверка конфигурации promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/)
