
wait_for_webui() {
    max_wait=10
    i=0

    while [ "$i" -lt "$max_wait" ]; do
        pidof nginx >/dev/null 2>&1 && return 0
        sleep 1
        i=$((i + 1))
    done

    return 1
}

apply_ipv6_state() {
    ipv6_disabled=
    ipv6_disabled=$(sysctl -n net.ipv6.conf.default.disable_ipv6 2>/dev/null || echo "0")

    [ "$ipv6_disabled" -eq 1 ] && return 0

    [ "$ipv6_support" != "off" ] && return 0

    ip -6 addr show 2>/dev/null | grep -q "inet6 " || return 0

    if ! wait_for_webui; then
        log_error_router "Веб-интерфейс роутера недоступен"
        return 1
    fi

    sleep 5
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1
    if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)" -eq 1 ] &&
       [ "$(sysctl -n net.ipv6.conf.default.disable_ipv6 2>/dev/null)" -eq 1 ]; then
        for dir in /proc/sys/net/ipv6/conf/t2s*; do
            if [ -f "$dir/disable_ipv6" ]; then
                echo "0" > "$dir/disable_ipv6"
            fi
        done
        log_info_router "Отключение IPv6 выполнено"
        return 0
    fi
}

get_ipver_support() {
    ip4_supported=$(ip -4 addr show 2>/dev/null | grep -q "inet " && echo true || echo false)
    ip6_supported=$(ip -6 addr show 2>/dev/null | grep -q "inet6 " && echo true || echo false)

    iptables_supported=$([ "$ip4_supported" = "true" ] && command -v iptables >/dev/null 2>&1 && echo true || echo false)
    ip6tables_supported=$([ "$ip6_supported" = "true" ] && command -v ip6tables >/dev/null 2>&1 && echo true || echo false)
}
