# -------------------------------------
# Цвета
# -------------------------------------
green="\033[92m"	# Зеленый
red="\033[91m"		# Красный
yellow="\033[93m"	# Желтый
light_blue="\033[96m"	# Голубой
italic="\033[3m"	# Курсив
reset="\033[0m"		# Сброс цветов

# -------------------------------------
# Директории
# -------------------------------------
tmp_dir_global="/opt/tmp"		 # Временная директория общая
tmp_dir="/opt/tmp/xkeen"		 # Временная директория XKeen
xtmp_dir="/opt/tmp/xray"		 # Временная директория Xray
mtmp_dir="/opt/tmp/mihomo"		 # Временная директория Mihomo
xkeen_dir="/opt/sbin/.xkeen"		 # Директория скриптов XKeen
xkeen_cfg="/opt/etc/xkeen"		 # Директория конфигурации XKeen
ipset_cfg="$xkeen_cfg/ipset"		 # Директория IPSET
xkeen_log_dir="/opt/var/log/xkeen"	 # Директория логов XKeen
xray_log_dir="/opt/var/log/xray"	 # Директория логов Xray
initd_dir="/opt/etc/init.d"		 # Директория init.d
pid_dir="/opt/var/run"			 # Директория pid файлов
backups_dir="/opt/backups"		 # Директория бекапов
install_dir="/opt/sbin"			 # Директория установки
geo_dir="/opt/etc/xray/dat"		 # Директория для dat
cron_dir="/opt/var/spool/cron/crontabs"	 # Директория планировщика
cron_file="root"			 # Файл планировщика
install_conf_dir="/opt/etc/xray/configs" # Директория конфигурации Xray
mihomo_conf_dir="/opt/etc/mihomo"	 # Директория конфигурации Mihomo
xray_conf_dir="$xkeen_dir/02_install/08_install_configs/02_configs_dir"
xkeen_var_file="$xkeen_dir/01_info/01_info_variable.sh"
register_dir="/opt/lib/opkg/info"
status_file="/opt/lib/opkg/status"
os_modules="/lib/modules/$(uname -r)"
user_modules="/opt/lib/modules"
xkeen_current_version="2.0"
xkeen_build="Beta"
build_timestamp=""

# -------------------------------------
# Файлы
# -------------------------------------
file_port_proxying="$xkeen_cfg/port_proxying.lst"
file_port_exclude="$xkeen_cfg/port_exclude.lst"
file_ip_exclude="$xkeen_cfg/ip_exclude.lst"
ru_exclude_ipv4="$ipset_cfg/ru_exclude_ipv4.lst"
ru_exclude_ipv6="$ipset_cfg/ru_exclude_ipv6.lst"
xkeen_config="$xkeen_cfg/xkeen.json"
initd_file="$initd_dir/S05xkeen"
initd_cron="$initd_dir/S05crond"

# -------------------------------------
# Время
# -------------------------------------
existing_content=$(cat "$status_file")
installed_size=$(du -s "$install_dir" | cut -f1)
source_date_epoch=$(date +%s)
current_datetime=$(date "+%d-%b-%y_%H-%M")

# -------------------------------------
# IP для проверки доступа в интернет
# -------------------------------------
conn_IP1="195.208.4.1"
conn_IP2="77.88.44.55"

# -------------------------------------
# URL — базовые префиксы (одно место для смены, если меняется хост)
# -------------------------------------
gh="https://github.com"
gh_raw="https://raw.githubusercontent.com"
gh_api="https://api.github.com/repos"
jsd="https://data.jsdelivr.com/v1/package/gh"

# Прокси для загрузок с GitHub (когда GH недоступен напрямую)
gh_proxy1="https://ghfast.top"
gh_proxy2="https://gh-proxy.com"

# -------------------------------------
# Репозитории — namespace'ы (одно место для смены при форке)
# -------------------------------------
# Сам XKeen. ВНИМАНИЕ: при смене обнови также xkeen_repo в install.sh
# и литералы install URL в README.md и test/README.md (markdown без переменных,
# install.sh — standalone bootstrap, нет доступа к этому файлу).
xkeen_repo="airaneel/XKeen-m"
xkeen_branch="main"

# Репозитории сторонних компонентов (не часть форка XKeen)
xray_repo="XTLS/Xray-core"
mihomo_repo="MetaCubeX/mihomo"
yq_upstream_repo="mikefarah/yq"
yq_workaround_repo="jameszeroX/yq"
zkeen_namespace="jameszeroX"            # zkeen-domains, zkeen-ip
refilter_repo="1andrevich/Re-filter-lists"
v2fly_domain_repo="v2fly/domain-list-community"
v2fly_geoip_repo="loyalsoldier/v2ray-rules-dat"

# -------------------------------------
# URL — собранные из префиксов и репозиториев
# -------------------------------------
# XKeen
xkeen_api_url="${gh_api}/${xkeen_repo}/releases/latest"
xkeen_jsd_url="${jsd}/${xkeen_repo}"
xkeen_tar_url="${gh}/${xkeen_repo}/releases/latest/download/xkeen.tar.gz"
xkeen_dev_url="${gh_raw}/${xkeen_repo}/${xkeen_branch}/test/xkeen.tar.gz"
xkeen_install_url="${gh_raw}/${xkeen_repo}/${xkeen_branch}/install.sh"
xkeen_offline_doc_url="${gh}/${xkeen_repo}/blob/${xkeen_branch}/docs/configuration.md#offline-установка"

# Xray
xray_api_url="${gh_api}/${xray_repo}/releases"
xray_jsd_url="${jsd}/${xray_repo}"
xray_zip_url="${gh}/${xray_repo}/releases/download"

# Mihomo
mihomo_api_url="${gh_api}/${mihomo_repo}/releases"
mihomo_jsd_url="${jsd}/${mihomo_repo}"
mihomo_gz_url="${gh}/${mihomo_repo}/releases/download"

# Yq (upstream и workaround-форк со совместимым yaml-парсером)
yq_upstream_dist_url="${gh}/${yq_upstream_repo}/releases/latest/download"
yq_workaround_dist_url="${gh}/${yq_workaround_repo}/releases/latest/download"
yq_workaround_issue_url="${gh}/${yq_upstream_repo}/issues/2609"

# Страницы релизов сторонних компонентов (для help-text при OffLine установке)
xray_releases_page_url="${gh}/${xray_repo}/releases/latest"
mihomo_releases_page_url="${gh}/${mihomo_repo}/releases/latest"
yq_releases_page_url="${gh}/${yq_upstream_repo}/releases/latest"

yq_use_workaround="true"  # отключить после исправления issue 2609 (по желанию)
get_yq_dist_url() {
    if [ "$yq_use_workaround" = "true" ]; then
        printf '%s\n' "$yq_workaround_dist_url"
    else
        printf '%s\n' "$yq_upstream_dist_url"
    fi
}

# Geo-файлы
refilter_url="${gh}/${refilter_repo}/releases/latest/download/geosite.dat"
refilterip_url="${gh}/${refilter_repo}/releases/latest/download/geoip.dat"
v2fly_url="${gh}/${v2fly_domain_repo}/releases/latest/download/dlc.dat"
v2flyip_url="${gh}/${v2fly_geoip_repo}/releases/latest/download/geoip.dat"
zkeen_url="${gh}/${zkeen_namespace}/zkeen-domains/releases/latest/download/zkeen.dat"
zkeenip_url="${gh}/${zkeen_namespace}/zkeen-ip/releases/latest/download/zkeenip.dat"
geoipv4_url="${gh}/${zkeen_namespace}/zkeen-ip/releases/latest/download/ru"
geoipv6_url="${gh}/${zkeen_namespace}/zkeen-ip/releases/latest/download/ru6"

# -------------------------------------
# Создание директорий и файлов
# -------------------------------------
mkdir -p "$xray_log_dir" || { echo "Ошибка: Не удалось создать директорию $xray_log_dir"; exit 1; }
mkdir -p "$initd_dir" || { echo "Ошибка: Не удалось создать директорию $initd_dir"; exit 1; }
mkdir -p "$pid_dir" || { echo "Ошибка: Не удалось создать директорию $pid_dir"; exit 1; }
mkdir -p "$backups_dir" || { echo "Ошибка: Не удалось создать директорию $backups_dir"; exit 1; }
mkdir -p "$install_dir" || { echo "Ошибка: Не удалось создать директорию $install_dir"; exit 1; }
mkdir -p "$cron_dir" || { echo "Ошибка: Не удалось создать директорию $cron_dir"; exit 1; }

# -------------------------------------
# Журналы
# -------------------------------------
xray_access_log="$xray_log_dir/access.log"
xray_error_log="$xray_log_dir/error.log"

touch "$xray_access_log" || { echo "Ошибка: Не удалось создать файл $xray_access_log"; exit 1; }
touch "$xray_error_log" || { echo "Ошибка: Не удалось создать файл $xray_error_log"; exit 1; }

# Таймаут curl
[ -e "/tmp/toff" ] && curl_timeout="" || curl_timeout="-m 180"
