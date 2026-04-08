
# Мониторинг файловых дескрипторов
monitor_fd() {
    while true; do
        client_pid=$(pidof "$name_client" | awk '{print $1}')
        if [ -n "$client_pid" ] && [ -d "/proc/$client_pid/fd" ]; then
            limit=$(awk '/Max open files/ {print $4}' "/proc/$client_pid/limits")
            set -- /proc/$client_pid/fd/*
            [ -e "$1" ] || set --
            current=$#
            if [ "$limit" -gt 0 ] && [ "$current" -gt $((limit * 90 / 100)) ]; then
                log_warning_router "$name_client открыл $current из $limit файловых дескрипторов, инициирован перезапуск"
                rm -f "$file_pid_fd"
                fd_out=true
                proxy_stop
                proxy_start "on"
                exit 0
            fi
        fi
        sleep "$delay_fd"
    done
}

load_ipset() {
    set="$1"
    file="$2"
    family="$3"

    ipset create "$set" hash:net family "$family" -exist
    ipset flush "$set"

    [ -f "$file" ] && sed -e 's/\r$//' -e 's/#.*//' -e '/^[[:space:]]*$/d' "$file" | awk '{print "add '"$set"' "$1}' | ipset restore -exist
}

# Останавливает фоновый monitor_fd (если запущен) и удаляет его pid-файл.
# Безопасно вызывать многократно: при отсутствии $file_pid_fd ничего не делает.
cleanup_fd_monitor() {
    [ -f "$file_pid_fd" ] || return 0
    kill "$(cat "$file_pid_fd")" 2>/dev/null
    rm -f "$file_pid_fd"
}

# Применяет архитектурно-зависимый ulimit -SHn для запускаемого прокси-клиента.
apply_fd_limit() {
    fd_limit="$other_fd"
    [ "$architecture" = "arm64-v8a" ] && fd_limit="$arm64_fd"
    ulimit -SHn "$fd_limit"
}
