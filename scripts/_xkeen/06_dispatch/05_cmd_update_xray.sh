# Обновление или установка ядра Xray (-ux).
cmd_update_xray() {
    test_connection
    test_github
    sleep 2

    . "/opt/sbin/.xkeen/01_info/03_info_cpu.sh"
    status_file="/opt/lib/opkg/status"
    info_cpu
    clear
    info_4g
    info_xray
    info_version_xray

    [ "$xray_installed" = "installed" ] && echo -e "  В роутере установлен Xray версии ${yellow}$xray_current_version${reset}" && echo
    download_xray

    if [ -z "$bypass_xray" ]; then
        if ! install_xray; then
            delete_tmp
            exit 1
        fi

        if [ "$xray_installed" = "installed" ]; then
            echo -e "  Выполняется отмена регистрации предыдущей версии ${yellow}Xray${reset}"
            delete_register_xray
            logs_delete_register_xray_info_console

            echo -e "  Выполняется регистрация новой версии ${yellow}Xray${reset}"
            register_xray_list
            logs_register_xray_list_info_console
            register_xray_control
            logs_register_xray_control_info_console
            register_xray_status
            logs_register_xray_status_info_console

            sleep 2
            if pidof xray >/dev/null; then
                $initd_file restart on >/dev/null 2>&1
            fi

            echo
            echo -e "  Обновление ядра Xray ${green}выполнено${reset}"
        else
            xray_installed="installed"
            info_version_xray

            if [ -f "$install_dir/xray" ]; then
                install_configs

                if [ ! -d "$geo_dir" ]; then
                    mkdir -p "$geo_dir"
                fi

                delete_register_xray
                echo
                echo -e "  Выполняется регистрация ${yellow}Xray${reset}"
                register_xray_list
                logs_register_xray_list_info_console
                register_xray_control
                logs_register_xray_control_info_console
                register_xray_status
                logs_register_xray_status_info_console
                sleep 2
                clear
                echo
                echo -e "  Установка ядра ${yellow}Xray${reset} ${green}выполнена${reset}"
            fi
        fi
    fi

    delete_tmp
}
