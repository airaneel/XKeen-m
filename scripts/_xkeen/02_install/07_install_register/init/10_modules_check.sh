
# Проверка, доступен ли модуль ядра. Принимает имя без расширения (например xt_TPROXY).
# Match/target может быть вкомпилирован в ядро — тогда его нет ни в lsmod, ни в
# /lib/modules, но он полностью работает. Поэтому при промахе по lsmod проверяем
# функционально: пробуем собрать правило во временной цепочке. Без этого на
# прошивках со встроенным multiport (KeeneticOS 5.02) get_modules молча обнулял
# port_donor/port_exclude, и прокси поднимался на всех портах, игнорируя
# исключения — при каждом старте, без единой ошибки в логе. (19.08.2026)
is_module_loaded() {
    lsmod | awk '{print $1}' | grep -qx "$1" && return 0

    case "$1" in
        xt_multiport) set -- -p tcp -m multiport --dports 1,2 -j RETURN ;;
        xt_dscp)      set -- -m dscp --dscp 0x00 -j RETURN ;;
        xt_socket)    set -- -m socket -j RETURN ;;
        xt_TPROXY)    set -- -p tcp -j TPROXY --on-port 1 --tproxy-mark 1 ;;
        *)            return 1 ;;
    esac

    probe_chain="xkeen_probe_$$"
    iptables -w -t mangle -N "$probe_chain" >/dev/null 2>&1 || return 1
    iptables -w -t mangle -A "$probe_chain" "$@" >/dev/null 2>&1
    probe_rc=$?
    iptables -w -t mangle -F "$probe_chain" >/dev/null 2>&1
    iptables -w -t mangle -X "$probe_chain" >/dev/null 2>&1
    return "$probe_rc"
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
