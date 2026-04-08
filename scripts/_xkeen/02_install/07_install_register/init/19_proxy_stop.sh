
# Остановка прокси-клиента
proxy_stop() {
    if ! proxy_status; then
        echo -e "  Прокси-клиент ${red}не запущен${reset}"
        cleanup_fd_monitor
    else
        [ -f "/tmp/xkeen_coldstart.lock" ] || log_info_router "Инициирована остановка прокси-клиента"
        cleanup_fd_monitor
        attempt=1
        while [ "$attempt" -le "$start_attempts" ]; do
            clean_firewall
            killall -q -9 "$name_client"
            sleep 1
            if ! proxy_status; then
                echo -e "  Прокси-клиент ${red}остановлен${reset}"
                [ -f "/tmp/xkeen_coldstart.lock" ] || log_info_router "Прокси-клиент успешно остановлен"
                rm -f "/tmp/xkeen_coldstart.lock"
                return 0
            fi
            attempt=$((attempt + 1))
        done
        echo -e "  Прокси-клиент ${red}не удалось остановить${reset}"
        log_error_terminal "Не удалось остановить прокси-клиент"
    fi
}
