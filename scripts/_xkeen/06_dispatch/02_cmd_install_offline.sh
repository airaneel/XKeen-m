# Установка XKeen OffLine (-io). Использует уже подложенные пользователем
# бинарники Xray/Mihomo/Yq в /opt/sbin без скачивания из сети.
cmd_install_offline() {
    clear
    echo
    check_keen_mode
    if [ -n "$keen_mode" ]; then
    echo -e "  ${red}Ошибка${reset}: Установка XKeen возможна только на Keenetic в режиме ${green}роутера${reset}"
        exit 1
    fi
    echo "  Установка XKeen OffLine"

    xkeen_set_info
    logs_cpu_info_console

    case "$architecture" in
        arm64-v8a|mips32le|mips32) ;;
        *) exit 1 ;;
    esac

    if [ -f "$install_dir/xray" ]; then
        chmod +x $install_dir/xray
    elif [ -f "$install_dir/mihomo" ]; then
        chmod +x $install_dir/mihomo
        if [ -f "$install_dir/yq" ]; then
            chmod +x $install_dir/yq
        else
            echo -e "  ${red}Не найден${reset} парсер конфигурационных файлов Mihomo - Yq"
            exit 1
        fi
    else
        clear
        echo
        echo -e "  ${red}Не найдено ядро проксирования xray или mihomo${reset}"
        echo
        echo -e "  Если планируете использовать ядро xray, поместите бинарник ${yellow}xray${reset}\n  архитектуры ${green}$architecture${reset} в директорию /opt/sbin/ и начните установку снова"
        echo -e "  Страница загрузок xray: ${yellow}${xray_releases_page_url}${reset}"
        echo
        echo -e "  Если планируете использовать ядро mihomo, поместите бинарники ${yellow}mihomo${reset} и ${yellow}yq${reset}\n  архитектуры ${green}$architecture${reset} в директорию /opt/sbin/ и начните установку снова"
        echo -e "  Страница загрузок mihomo: ${yellow}${mihomo_releases_page_url}${reset}"
        echo -e "  Страница загрузок yq: ${yellow}${yq_releases_page_url}${reset}"
        echo
        exit 1
    fi

    if [ -f "$install_dir/xray" ]; then
        install_configs

        if [ ! -d "$geo_dir" ]; then
            mkdir -p "$geo_dir"
        fi

        clear
        delete_register_xray
        echo
        echo -e "  Выполняется регистрация ${yellow}Xray${reset}"
        register_xray_list
        logs_register_xray_list_info_console
        register_xray_control
        logs_register_xray_control_info_console
        register_xray_status
        logs_register_xray_status_info_console
    fi

    if [ -f "$install_dir/mihomo" ]; then
        add_mihomo_config
        delete_register_mihomo
        echo
        echo -e "  Выполняется регистрация ${yellow}Mihomo${reset}"
        register_mihomo_list
        logs_register_mihomo_list_info_console
        register_mihomo_control
        logs_register_mihomo_control_info_console
        register_mihomo_status
        logs_register_mihomo_status_info_console
        register_yq_list
        logs_register_yq_list_info_console
        register_yq_control
        logs_register_yq_control_info_console
        register_yq_status
        logs_register_yq_status_info_console
        sleep 2
    fi

    clear
    delete_register_xkeen
    echo
    echo -e "  Выполняется регистрация ${yellow}XKeen${reset}"
    register_xkeen_list
    logs_register_xkeen_list_info_console

    register_xkeen_control
    logs_register_xkeen_control_info_console

    register_xkeen_status
    logs_register_xkeen_status_info_console

    migrate_ports_from_initd
    register_xkeen_initd
    create_xkeen_cfg

    fixed_register_packages

    clear
    choice_autostart_xkeen
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
    echo
    echo -e "  Для использования ядра '${yellow}$Xray${reset}'"
    echo -e "  1. Поместите необходимые геофайлы в директорию '${yellow}$geo_dir/${reset}'"
    echo -e "  2. Настройте конфигурацию Xray по пути '${yellow}$install_conf_dir/${reset}'"
    echo -e "  3. Запустите XKeen командой ${yellow}xkeen -start${reset}"
    echo -e "  4. ${green}Enjoy!${reset}"
    echo
    echo -e "  Для использования ядра ${yellow}Mihomo${reset}"
    echo -e "  1. Настройте конфигурацию Mihomo в файле '${yellow}$mihomo_conf_dir/config.yaml${reset}'"
    echo -e "  2. Переключите ядро проксирования командой ${yellow}xkeen -mihomo${reset}"
    echo -e "  3. Запустите XKeen командой ${yellow}xkeen -start${reset}"
    echo -e "  4. ${green}Enjoy!${reset}"
    echo
    echo -e "  Для вывода Справки выполните ${yellow}xkeen -h${reset}"
}
