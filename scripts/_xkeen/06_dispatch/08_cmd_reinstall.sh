# Переустановка XKeen (-k) и пост-установка после exec'а (-k_post_install).
# В отличие от -uk, тут пользователю даётся выбор: качать новый архив или
# использовать уже распакованный (только переустановить пакеты + регистрацию).

cmd_reinstall() {
    . "/opt/sbin/.xkeen/01_info/03_info_cpu.sh"
    status_file="/opt/lib/opkg/status"
    xkeen_info
    xkeen_set_info

    clear
    echo
    echo -e "  Переустановка ${yellow}XKeen${reset}"

    choice_redownload_xkeen
    if [ -n "$redownload_xkeen" ]; then
        if [ "$xkeen_build" = "Stable" ]; then
            download_func="download_xkeen"
        else
            download_func="download_xkeen_dev"
        fi
        test_connection
        test_entware
        test_github
        sleep 2
        "$download_func"
    else
        opkg update >/dev/null 2>&1
        info_packages
        install_packages
    fi

    echo
    install_xkeen

    # Перезапуск скрипта
    grep -E "^\s*-k_post_install\s*\)" "$0" > /dev/null && exec sh "$0" -k_post_install
}

cmd_reinstall_post() {
    . "/opt/sbin/.xkeen/import.sh"
    xkeen_info
    xkeen_set_info
    info_packages
    install_packages

    echo -e "  Выполняется отмена регистрации предыдущей версии ${yellow}XKeen${reset}"
    delete_register_xkeen
    logs_delete_register_xkeen_info_console

    echo -e "  Выполняется регистрация новой версии ${yellow}XKeen${reset}"
    register_xkeen_list
    logs_register_xkeen_list_info_console

    register_xkeen_control
    logs_register_xkeen_control_info_console

    register_xkeen_status
    logs_register_xkeen_status_info_console

    register_cron_initd
    migrate_ports_from_initd
    register_xkeen_initd
    create_xkeen_cfg
    choice_cancel_cron_select=true
    update_cron_geofile_task
    fixed_register_packages

    if pidof xray >/dev/null || pidof mihomo >/dev/null ; then
        $initd_file restart on >/dev/null 2>&1
    fi

    delete_tmp

    echo
    echo -e "  Переустановка XKeen ${green}выполнена${reset}"
}
