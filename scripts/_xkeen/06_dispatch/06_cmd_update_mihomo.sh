# Обновление или установка ядра Mihomo (-um).
cmd_update_mihomo() {
    test_connection
    test_github
    sleep 2

    . "/opt/sbin/.xkeen/01_info/03_info_cpu.sh"
    status_file="/opt/lib/opkg/status"
    info_cpu
    clear
    info_4g
    info_mihomo
    info_version_mihomo
    mihomo_was_installed="$mihomo_installed"

    [ "$mihomo_installed" = "installed" ] && echo -e "  В роутере установлен Mihomo версии ${yellow}$mihomo_current_version${reset}" && echo
    if ! download_mihomo; then
        delete_tmp
        exit 1
    fi
    info_version_mihomo
    info_version_yq

    if [ -z "$bypass_mihomo" ]; then
        if ! install_mihomo; then
            delete_tmp
            exit 1
        fi
        info_mihomo

        if [ "$mihomo_installed" != "installed" ]; then
            delete_tmp
            echo -e "  ${red}Ошибка${reset}: Mihomo не установлен, так как отсутствует обязательный Yq"
            exit 1
        elif [ "$mihomo_was_installed" = "installed" ]; then
            echo -e "  Выполняется отмена регистрации предыдущей версии ${yellow}Mihomo${reset}"
            delete_register_mihomo
            logs_delete_register_mihomo_info_console
            logs_delete_register_yq_info_console

            echo -e "  Выполняется регистрация новой версии ${yellow}Mihomo${reset}"
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

            if pidof mihomo >/dev/null; then
                $initd_file restart on >/dev/null 2>&1
            fi
            echo
            echo -e "  Обновление ядра ${yellow}Mihomo${reset} ${green}выполнено${reset}"
        else
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
            clear
            echo
            echo -e "  Установка ядра ${yellow}Mihomo${reset} ${green}выполнена${reset}"
        fi
    fi

    delete_tmp
}
