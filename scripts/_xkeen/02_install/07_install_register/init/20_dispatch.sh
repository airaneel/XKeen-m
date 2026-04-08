
# Менеджер команд
case "$1" in
    start)
        ipset create ext_exclude hash:ip family inet -exist
        ipset create ext_exclude6 hash:ip family inet6 -exist
        if [ -z "$2" ]; then
            [ "$start_auto" != "on" ] && exit 0
            log_info_router "Подготовка к запуску прокси-клиента"
            nohup sh -c "sleep $start_delay && $0 restart" >/dev/null 2>&1 &
            touch "/tmp/xkeen_coldstart.lock"
            exit 0
        fi
        proxy_start "$2"
    ;;
    stop) proxy_stop ;;
    status)
        if proxy_status; then
            mode_proxy=$(grep '^mode_proxy=' $file_netfilter_hook | awk -F'"' '{print $2}')
            echo -e "  Прокси-клиент ${yellow}$name_client${reset} ${green}запущен${reset} в режиме ${light_blue}$mode_proxy${reset}"
        else
            echo -e "  Прокси-клиент ${red}не запущен${reset}"
        fi
        ;;
    restart) proxy_stop; proxy_start "$2" ;;
    *) echo -e "  Команды: ${green}start${reset} | ${red}stop${reset} | ${yellow}restart${reset} | status" ;;
esac

exit 0
