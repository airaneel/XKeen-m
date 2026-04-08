# Управление cron-задачей автообновления геофайлов и пересоздание init файла.

cmd_setup_cron_geo() {
    info_cron
    clear
    echo -e "  Создание или изменение задачи автообновления баз ${yellow}GeoFile/GeoIPSET${reset}"
    choice_update_cron
    update_cron_geofile_task
    choice_cron_time
    install_cron
    delete_tmp
    echo -e "  Создание или изменение задачи автообновления баз GeoFile/GeoIPSET ${green}выполнено${reset}"
}

cmd_remove_cron_geo() {
    clear
    echo
    choice_for_remove="задачу автообновления баз GeoFile/GeoIPSET"
    choice_remove

    info_cron

    clear
    echo
    echo -e "  Удаление задачи автообновления баз ${yellow}GeoFile/GeoIPSET${reset}"

    delete_cron_geofile
    logs_delete_cron_geofile_info_console
    delete_tmp

    echo -e "  Удаление задачи автообновления баз GeoFile/GeoIPSET ${green}выполнено${reset}"
}

cmd_recreate_init() {
    clear
    $initd_file stop >/dev/null 2>&1
    [ -e "$initd_file" ] && rm -f "$initd_file"

    echo -e "  Создание файла автозапуска ${yellow}XKeen${reset}"
    sleep 1

    migrate_ports_from_initd
    register_xkeen_initd
    logs_register_xkeen_initd_info_console

    echo
    echo -e "  Создание файла автозапуска XKeen ${green}выполнено${reset}"
    echo -e "  Если конфигурация настроена, то можете запустить проксирование командой '${yellow}xkeen -start${reset}'"
}
