#!/bin/sh

# Информация о службе: Запуск / Остановка XKeen
# Версия: 2.29

# Окружение
PATH="/opt/bin:/opt/sbin:/sbin:/bin:/usr/sbin:/usr/bin"

# Цвета
green="\033[92m"
red="\033[91m"
yellow="\033[93m"
light_blue="\033[96m"
reset="\033[0m"

# Имена
name_client="xray"
name_app="XKeen"
name_policy="xkeen"
name_profile="xkeen"
name_chain="xkeen"

# Директории
directory_os_modules="/lib/modules/$(uname -r)"
directory_user_modules="/opt/lib/modules"
directory_configs_app="/opt/etc/$name_client"
directory_xray_config="$directory_configs_app/configs"
directory_xray_asset="$directory_configs_app/dat"
directory_logs="/opt/var/log"
xkeen_cfg="/opt/etc/xkeen"
ipset_cfg="$xkeen_cfg/ipset"
install_dir="/opt/sbin"

# Файлы
file_netfilter_hook="/opt/etc/ndm/netfilter.d/proxy.sh"
log_access="$directory_logs/$name_client/access.log"
log_error="$directory_logs/$name_client/error.log"
mihomo_config="$directory_configs_app/config.yaml"
file_port_proxying="$xkeen_cfg/port_proxying.lst"
file_port_exclude="$xkeen_cfg/port_exclude.lst"
file_ip_exclude="$xkeen_cfg/ip_exclude.lst"
xkeen_config="$xkeen_cfg/xkeen.json"
file_pid_fd="/var/run/xkeen_fd.pid"
ru_exclude_ipv4="$ipset_cfg/ru_exclude_ipv4.lst"
ru_exclude_ipv6="$ipset_cfg/ru_exclude_ipv6.lst"

# URL
url_server="localhost:79"
url_policy="rci/show/ip/policy"
url_keenetic_port="rci/ip/http"
url_redirect_port="rci/ip/static"

# Настройки правил iptables
table_id="111"
table_mark="0x111"
table_redirect="nat"
table_tproxy="mangle"
custom_mark=""

# DSCP-метки
dscp_exclude="62"
dscp_proxy="63"

ipv4_proxy="127.0.0.1"
ipv4_exclude="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4 255.255.255.255"
ipv6_proxy="::1"
ipv6_exclude="::/128 ::1/128 64:ff9b::/96 2001::/32 2002::/16 fd00::/8 ff00::/8 fe80::/10"

# Перехват DNS в прокси
proxy_dns="off"

# Проксирование трафика Entware
proxy_router="off"

# Настройки запуска
start_attempts=10
start_auto="on"
start_delay=20

# Контроль файловых дескрипторов
check_fd="off"
arm64_fd=40000
other_fd=10000
delay_fd=20

# Поддержка IPv6
ipv6_support="on"

## Расширенные сообщения запуска
extended_msg="off"

## Резервное копирование XKeen при обновлении
backup="on"

## Клиенты XKeen под своими IP в журнале AdGuard Home
aghfix="off"
