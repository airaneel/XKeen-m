
# Проверка, загружен ли модуль ядра. Принимает имя без расширения (например xt_TPROXY).
is_module_loaded() {
    lsmod | awk '{print $1}' | grep -qx "$1"
}

# Загрузка модулей
load_modules() {
    module="$1"
    name="${module%.ko}"

    if ! is_module_loaded "$name"; then
        for dir in "$directory_os_modules" "$directory_user_modules"; do
            if [ -f "$dir/$module" ]; then
                insmod "$dir/$module" >/dev/null 2>&1 && return
            fi
        done
    fi
}

# Обработка модулей и портов
get_modules() {
    load_modules xt_TPROXY.ko
    load_modules xt_socket.ko
    load_modules xt_multiport.ko
    load_modules xt_dscp.ko

    if [ "$mode_proxy" = "TProxy" ] || [ "$mode_proxy" = "Hybrid" ]; then
        for module in xt_TPROXY.ko xt_socket.ko; do
            if ! is_module_loaded "${module%.ko}"; then
                proxy_stop
                log_error_router "Модуль ${module} не загружен"
                log_error_terminal "
  Модуль '${light_blue}${module}${reset}' не загружен
  Невозможно запустить прокси в режиме ${mode_proxy} без него
  Установите компонент роутера '${yellow}Модули ядра подсистемы Netfilter${reset}'
"
            fi
        done
    fi

    if [ -n "$port_donor" ] || [ -n "$port_exclude" ]; then
        if ! is_module_loaded xt_multiport; then
            log_warning_router "Модуль xt_multiport не загружен"
            log_warning_terminal "
  Модуль '${light_blue}xt_multiport${reset}' не загружен
  Невозможно использовать выбранные порты без него
  Установите компонент роутера '${yellow}Модули ядра подсистемы Netfilter${reset}'

  Прокси будет запущен на всех портах
"
            port_donor=""
            port_exclude=""
        fi
    fi

    if [ -n "$dscp_exclude" ] || [ -n "$dscp_proxy" ]; then
        if ! is_module_loaded xt_dscp; then
            log_warning_router "Модуль xt_dscp не загружен"
            log_warning_terminal "
  Модуль '${light_blue}xt_dscp${reset}' не загружен
  Работа с DSCP-метками невозможна
  Установите компонент роутера '${yellow}Модули ядра подсистемы Netfilter${reset}'
"
            dscp_exclude=""
            dscp_proxy=""
        fi
    fi
}
