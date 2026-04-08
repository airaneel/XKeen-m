
# Запуск прокси-клиента
proxy_start() {
    start_manual="$1"
    if [ "$start_manual" = "on" ] || [ "$start_auto" = "on" ]; then
        apply_ipv6_state
        get_ipver_support

        case "$name_client" in
            xray)
                if [ ! -x "$install_dir/xray" ]; then
                    log_error_terminal "$(printf "$missing_files_template" "$install_dir/xray")"
                fi
                ;;
            mihomo)
                if [ ! -x "$install_dir/mihomo" ] || [ ! -x "$install_dir/yq" ]; then
                    missing_files=""
                    [ ! -x "$install_dir/yq" ] && missing_files="$install_dir/yq"
                    [ ! -x "$install_dir/mihomo" ] && missing_files="$install_dir/mihomo\n  $missing_files"
                    log_error_terminal "$(printf "$missing_files_template" "$missing_files")"
                fi
                ;;
        esac

        validate_xkeen_json
        check_policy_name_conflict
        check_xray_backups
        validate_routing_mark
        log_clean
        api_cache_init
        process_user_ports
        process_custom_mark
        port_redirect=$(get_port_redirect)
        network_redirect=$(get_network_redirect)
        port_tproxy=$(get_port_tproxy)
        network_tproxy=$(get_network_tproxy)
        mode_proxy=$(get_mode_proxy)
        if [ "$mode_proxy" != "Other" ]; then
            policy_mark=$(get_policy_mark)

            if [ -n "$policy_mark" ]; then
                user_policies=$(resolve_user_policies)

                if [ -n "$user_policies" ]; then
                    print_policy_info "yes" "yes"
                else
                    print_policy_info "yes" "no"
                fi
            else
                raw_user_policies=$(get_user_policies)
                ignored_custom="no"

                if [ -n "$raw_user_policies" ]; then
                    ignored_custom="yes"
                fi

                print_policy_info "no" "no" "$ignored_custom"

                user_policies=""
            fi

            networks=$(printf '%s\n' $network_redirect $network_tproxy | tr ',' ' ' | tr -s ' ' '\n' | sort -u | tr '\n' ' ')
            networks=${networks% }

            if [ -n "$policy_mark" ] && [ -z "$port_donor" ]; then
                port_exclude=$(get_port_exclude)
            fi
            if ! proxy_status && { [ -n "$port_donor" ] || [ -n "$port_exclude" ] || [ "$mode_proxy" = "TProxy" ] || [ "$mode_proxy" = "Hybrid" ]; }; then
                get_modules
            fi
            if [ "$mode_proxy" = "TProxy" ]; then
                keenetic_ssl="$(get_keenetic_port)" || {
                    proxy_stop
                    log_error_router "Порт 443 занят сервисами Keenetic"
                    log_error_terminal "
  Необходимый для режима ${light_blue}TProxy${reset} ${red}443 порт занят${reset} сервисами Keenetic

  Освободите его на странице 'Пользователи и доступ' веб-интерфейса роутера
"
                }
            fi
        fi
        if proxy_status; then
            echo -e "  Прокси-клиент уже ${green}запущен${reset}"
            [ "$mode_proxy" != "Other" ] && configure_firewall
            if [ "$start_manual" = "on" ]; then
                log_error_terminal "Не удалось запустить ${yellow}$name_client${reset}, так как он уже запущен"
            else
                log_info_router "Прокси-клиент успешно запущен в режиме $mode_proxy"
            fi
        else
            log_info_router "Инициирован запуск прокси-клиента"
            attempt=1
            . "/opt/sbin/.xkeen/01_info/03_info_cpu.sh"
            status_file="/opt/lib/opkg/status"
            info_cpu
            while [ "$attempt" -le "$start_attempts" ]; do
                case "$name_client" in
                    xray)
                        export XRAY_LOCATION_CONFDIR="$directory_xray_config"
                        export XRAY_LOCATION_ASSET="$directory_xray_asset"
                        find "$directory_xray_config" -maxdepth 1 -name '._*.json' -type f -delete
                        apply_fd_limit
                        if [ -n "$fd_out" ]; then
                            nohup "$name_client" run >/dev/null 2>&1 &
                            unset fd_out
                        else
                            "$name_client" run &
                        fi
                    ;;
                    mihomo)
                        export CLASH_HOME_DIR="$directory_configs_app"
                        apply_fd_limit
                        if [ -n "$fd_out" ]; then
                            nohup "$name_client" >/dev/null 2>&1 &
                            unset fd_out
                        else
                            "$name_client" &
                        fi
                        ;;
                    *) log_error_terminal "Неизвестный прокси-клиент: ${yellow}$name_client${reset}" ;;
                esac
                sleep 2
                if proxy_status; then
                    [ "$mode_proxy" != "Other" ] && configure_firewall
                    [ "$iptables_supported" = "true" ] && [ -f "$ru_exclude_ipv4" ] && load_ipset geo_exclude "$ru_exclude_ipv4" inet
                    [ "$ip6tables_supported" = "true" ] && [ -f "$ru_exclude_ipv6" ] && load_ipset geo_exclude6 "$ru_exclude_ipv6" inet6
                    load_user_ipset
                    echo -e "  Прокси-клиент ${green}запущен${reset} в режиме ${light_blue}${mode_proxy}${reset}"
                    if [ -n "$api_policy_json" ]; then
                        if echo "$api_policy_json" | jq --arg policy "$name_policy" -e 'any(.[]; .description | ascii_downcase == $policy)' > /dev/null; then
                            if [ -e "/tmp/noinet" ]; then
                                echo
                                echo -e "  У политики ${yellow}$name_policy${reset} ${red}нет доступа в интернет${reset}"
                                echo "  Проверьте, установлена ли галка на подключении к провайдеру"
                            fi
                        fi
                    fi
                    [ "$mode_proxy" = "Other" ] && echo -e "  Функция прозрачного прокси ${red}не активна${reset}. Направляйте соединения на ${yellow}${name_client}${reset} вручную"
                    log_info_router "Прокси-клиент успешно запущен в режиме $mode_proxy"
                    if [ "$check_fd" = "on" ]; then
                        cleanup_fd_monitor
                        monitor_fd &
                        echo $! > "$file_pid_fd"
                        log_info_router "Запущен контроль файловых дескрипторов $name_client"
                    fi
                    return 0
                fi
                attempt=$((attempt + 1))
            done
            echo -e "  ${red}Не удалось запустить${reset} прокси-клиент"
            log_error_terminal "Не удалось запустить прокси-клиент"
        fi
    else
        clean_firewall
    fi
}
