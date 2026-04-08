# Phase-helpers для cmd_install (-i). Вынесены в отдельный файл, чтобы 01_cmd_install.sh
# уложился в ≤200 строк. Это НЕ публичные команды CLI — только внутренние шаги.

# Phase 1: загрузка/установка Xray + GeoSite + GeoIP
_install_xray_phase() {
    if [ "$add_xray" = "true" ]; then
        clear
        echo
        download_xray
    else
        command -v xray >/dev/null 2>&1 || bypass_xray="true"
    fi

    if [ -z "$bypass_xray" ]; then
        if install_xray; then
            xray_installed="installed"

            clear
            # Устанавливаем GeoSite
            choice_geosite
            delete_geosite
            install_geosite
            sleep 2

            clear
            # Устанавливаем GeoIP
            choice_geoip
            delete_geoip
            install_geoip
            sleep 2
        else
            echo -e "  ${red}Установка Xray прервана${reset} — пропускаем регистрацию и геофайлы"
            bypass_xray="true"
        fi
    fi
}

# Phase 2: регистрация Xray (после успешной установки + cron + configs)
_install_xray_register_phase() {
    if [ -z "$bypass_xray" ]; then
        info_version_xray
        delete_register_xray

        echo -e "  Выполняется регистрация ${yellow}Xray${reset}"
        register_xray_list
        logs_register_xray_list_info_console

        register_xray_control
        logs_register_xray_control_info_console

        register_xray_status
        logs_register_xray_status_info_console
        sleep 2
    fi
}

# Phase 3: загрузка/установка/регистрация Mihomo
_install_mihomo_phase() {
    if [ "$add_mihomo" = "true" ]; then
        clear
        echo
        if ! download_mihomo; then
            bypass_mihomo="true"
        fi
    else
        command -v mihomo >/dev/null 2>&1 || bypass_mihomo="true"
    fi

    if [ -z "$bypass_mihomo" ]; then
        if ! install_mihomo; then
            bypass_mihomo="true"
            echo -e "  ${red}Установка Mihomo прервана${reset} — пропускаем регистрацию"
        fi
    fi

    if [ -z "$bypass_mihomo" ]; then
        info_mihomo
        if [ "$mihomo_installed" = "installed" ]; then
            info_version_mihomo
            info_version_yq
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
        else
            echo -e "  ${red}Ошибка${reset}: Mihomo не установлен, так как отсутствует обязательный Yq"
        fi
    fi

    if [ "$add_mihomo" = "true" ] && [ "$mihomo_installed" != "installed" ] && [ "$xray_installed" != "installed" ]; then
        echo -e "  ${red}Ошибка${reset}: Mihomo не установлен, так как отсутствует обязательный Yq"
        exit 1
    fi
}

# Phase 4: регистрация XKeen + создание init + autostart
_install_xkeen_register_phase() {
    if [ "$xray_installed" = "installed" ] || [ "$mihomo_installed" = "installed" ]; then
        delete_register_xkeen
        clear
        echo
        echo -e "  Выполняется регистрация ${yellow}XKeen${reset}"
        register_xkeen_list
        logs_register_xkeen_list_info_console

        register_xkeen_control
        logs_register_xkeen_control_info_console

        register_xkeen_status
        logs_register_xkeen_status_info_console

        fixed_register_packages

        migrate_ports_from_initd
        register_xkeen_initd
        create_xkeen_cfg
        sleep 2

        clear
        choice_autostart_xkeen
    fi
}

# Phase 5: переключение name_client в init файле, если установлено только одно ядро
_install_switch_core() {
    if [ "$xray_installed" != "installed" ] && [ "$mihomo_installed" = "installed" ]; then
        if [ -f "$install_dir/mihomo" ] && [ -f "$install_dir/yq" ] && grep -q 'name_client="xray"' $initd_file; then
            sed -i 's/name_client="xray"/name_client="mihomo"/' $initd_file
        fi
    elif  [ "$xray_installed" = "installed" ] && [ "$mihomo_installed" != "installed" ]; then
        if [ -f "$install_dir/xray" ] && grep -q 'name_client="mihomo"' $initd_file; then
            sed -i 's/name_client="mihomo"/name_client="xray"/' $initd_file
        fi
    fi
}

# Phase 6: финальные сообщения с инструкциями для пользователя
_install_print_finish_messages() {
    if [ "$xray_installed" = "installed" ] || [ "$mihomo_installed" = "installed" ]; then
        if grep -q 'name_client="xray"' $initd_file; then
            echo -e "  1. Настройте конфигурацию Xray по пути '${yellow}$install_conf_dir/${reset}'"
            echo -e "  2. Запустите XKeen командой ${yellow}xkeen -start${reset}"
            echo -e "  3. ${green}Enjoy!${reset}"
            echo
        elif grep -q 'name_client="mihomo"' $initd_file; then
            echo -e "  1. Настройте конфигурацию Mihomo в файле '${yellow}$mihomo_conf_dir/config.yaml${reset}'"
            echo -e "  2. Запустите XKeen командой ${yellow}xkeen -start${reset}"
            echo -e "  3. ${green}Enjoy!${reset}"
            echo
        fi
    fi

    if [ "$xray_installed" = "installed" ] && [ "$mihomo_installed" = "installed" ]; then
        if grep -q 'name_client="xray"' $initd_file; then
            echo -e "  Если хотите переключить XKeen на ядро ${yellow}Mihomo${reset}"
            echo
            echo -e "  1. Настройте конфигурацию Mihomo в файле '${yellow}$mihomo_conf_dir/config.yaml${reset}'"
            echo -e "  2. Переключите ядро проксирования командой ${yellow}xkeen -mihomo${reset}"
            echo -e "  3. Запустите XKeen командой ${yellow}xkeen -start${reset}"
            echo -e "  4. ${green}Enjoy!${reset}"
        elif grep -q 'name_client="mihomo"' $initd_file; then
            echo -e "  Если хотите переключить XKeen на ядро ${yellow}Xray${reset}"
            echo
            echo -e "  1. Настройте конфигурацию Xray по пути '${yellow}$install_conf_dir/${reset}'"
            echo -e "  2. Переключите ядро проксирования командой ${yellow}xkeen -xray${reset}"
            echo -e "  3. Запустите XKeen командой ${yellow}xkeen -start${reset}"
            echo -e "  4. ${green}Enjoy!${reset}"
        fi
    echo
    fi
}
