# Управление портами проксирования и портами-исключениями: -ap, -dp, -cp, -ape, -dpe, -cpe.
# Также -tp (показать прослушиваемые порты прокси-клиента).
#
# ВНИМАНИЕ: cmd_ports_add / cmd_ports_del / cmd_ports_exclude_add / cmd_ports_exclude_del
# принимают аргументы как $@. Главный диспетчер делает `shift; cmd_X "$@"` чтобы
# передать всё, что было после флага. Внутри функции `$*` собирает их в одну строку
# для передачи в add_ports_donor / dell_ports_donor / etc.

cmd_ports_add() {
    add_ports_donor "$*"
    sleep 2
    add_chmod_init
    if pidof xray >/dev/null || pidof mihomo >/dev/null; then
        $initd_file restart on >/dev/null 2>&1
    fi
}

cmd_ports_del() {
    dell_ports_donor "$*"
    sleep 2
    add_chmod_init
    if pidof xray >/dev/null || pidof mihomo >/dev/null; then
        $initd_file restart on >/dev/null 2>&1
    fi
}

cmd_ports_list() {
    get_ports_donor
}

cmd_ports_exclude_add() {
    add_ports_exclude "$*"
    sleep 2
    add_chmod_init
    if pidof xray >/dev/null || pidof mihomo >/dev/null; then
        $initd_file restart on >/dev/null 2>&1
    fi
}

cmd_ports_exclude_del() {
    dell_ports_exclude "$*"
    sleep 2
    add_chmod_init
    if pidof xray >/dev/null || pidof mihomo >/dev/null; then
        $initd_file restart on >/dev/null 2>&1
    fi
}

cmd_ports_exclude_list() {
    get_ports_exclude
}

cmd_ports_listening() {
    echo "  Определение прослушиваемых портов"
    tests_ports_client
}
