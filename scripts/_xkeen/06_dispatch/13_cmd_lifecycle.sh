# Жизненный цикл прокси-клиента и контроль файловых дескрипторов:
# -start, -stop, -restart, -status, -auto, -fd.

cmd_start() {
    add_chmod_init
    $initd_file start on
}

cmd_stop() {
    add_chmod_init
    $initd_file stop
}

cmd_restart() {
    add_chmod_init
    $initd_file restart on
}

cmd_status() {
    $initd_file status
}

cmd_autostart() {
    clear
    change_autostart_xkeen
    add_chmod_init
}

cmd_toggle_fd() {
    clear
    change_file_descriptors
}
