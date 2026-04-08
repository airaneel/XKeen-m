# Полный цикл установки XKeen (-i / -install).
# Phases-helpers вынесены в 01a_cmd_install_phases.sh, чтобы файл влез в ≤200 строк.
cmd_install() {
    test_connection
    test_entware
    test_github
    sleep 2

    . "$script_dir/.xkeen/import.sh"
    clear
    echo
    check_keen_mode
    if [ -n "$keen_mode" ]; then
    echo -e "  ${red}Ошибка${reset}: Установка XKeen возможна только на Keenetic в режиме ${green}роутера${reset}"
        exit 1
    fi

    echo -e "  Запуск полного цикла установки ${yellow}XKeen${reset}"

    xkeen_info
    xkeen_set_info
    info_4g
    logs_cpu_info_console

    case "$architecture" in
        arm64-v8a|mips32le|mips32) ;;
        *) exit 1 ;;
    esac

    location_entware_storage
    preinstall_warn

    choice_add_proxy_cores

   if [ "$xray_installed" != "installed" ] && [ "$mihomo_installed" != "installed" ] &&
      [ "$add_xray" = "false" ] && [ "$add_mihomo" = "false" ]; then
       echo -e "  ${red}Невозможно установить${reset} XKeen без ядра проксирования"
       exit 1
   fi

    _install_xray_phase

        clear
        # Устанавливаем GeoIPSET
        install_geoipset init
        sleep 2

        if [ "$bypass_cron_geosite" = "false" ] || [ "$bypass_cron_geoip" = "false" ] || [ "$bypass_cron_geoipset" = "false" ]; then
            clear
            # Настраиваем автоматические обновления
            info_cron
            choice_update_cron
            update_cron_geofile_task
            clear
            choice_cron_time
            install_cron
            sleep 2
        fi

        clear
        echo
        install_configs

        # Создаем init для cron
        "$initd_cron" stop >/dev/null 2>&1
        [ -e "$initd_cron" ] && rm -f "$initd_cron"
        register_cron_initd
        "$initd_cron" start >/dev/null 2>&1

    _install_xray_register_phase
    _install_mihomo_phase
    _install_xkeen_register_phase
    _install_switch_core
    add_chmod_init

    if pidof xray >/dev/null || pidof mihomo >/dev/null ; then
        $initd_file restart on >/dev/null 2>&1
    fi

    # Удаляем временные файлы
    delete_tmp
    sleep 2

    clear
    echo
    echo -e "  ${green}Установка XKeen завершена!${reset}"

    _install_print_finish_messages

    echo -e "  Для вывода Справки выполните ${yellow}xkeen -h${reset}"
}
