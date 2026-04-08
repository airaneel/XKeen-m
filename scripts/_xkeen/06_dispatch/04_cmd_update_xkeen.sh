# Обновление самого XKeen (-uk) и пост-обновление после exec'а на новую версию (-uk_post_update).
# -uk запускается на текущей версии: качает архив, распаковывает и exec'ит новую копию
# с флагом -uk_post_update, которая дальше делает регистрацию.

cmd_update_xkeen() {
    test_connection
    test_github
    sleep 2

    clear
    echo
    echo "  Проверка обновлений XKeen"
    xkeen_info
    xkeen_set_info

    if [ "$xkeen_build" != "Stable" ]; then
        download_func="download_xkeen_dev"
    else
        if [ "$info_compare_xkeen" = "actual" ]; then
            echo "  Нет доступных обновлений XKeen"
            exit 0
        else
            echo -e "  Найдена новая версия ${yellow}XKeen${reset}"
            download_func="download_xkeen"
        fi
    fi

    backup_xkeen
    $download_func
    install_xkeen

    # Перезапуск скрипта
    grep -E "^\s*-uk_post_update\s*\)" "$0" > /dev/null && exec sh "$0" -uk_post_update
}

cmd_update_xkeen_post() {
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

    echo -e "  Обновление XKeen ${green}выполнено${reset}"
}
