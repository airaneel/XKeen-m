
log_clean() {
    [ "$name_client" = "xray" ] && : > "$log_access" && : > "$log_error"
}

api_cache_init() {
    api_policy_json=$(curl -kfsS "${url_server}/${url_policy}" 2>/dev/null)
    api_port_json=$(curl -kfsS "${url_server}/${url_keenetic_port}" 2>/dev/null)
    api_static_json=$(curl -kfsS "${url_server}/${url_redirect_port}" 2>/dev/null)
}

refresh_port_cache() {
    api_port_json=$(curl -kfsS "${url_server}/${url_keenetic_port}" 2>/dev/null)
}

json_get_ports() {
    if [ -n "$api_port_json" ]; then
        printf '%s' "$api_port_json" | jq -r '.port, (.ssl.port // empty)' 2>/dev/null
    fi
}

# Получение портов Keenetic
get_keenetic_port() {
    ports=""
    ports=$(json_get_ports)

    case " $ports " in
        *" 443 "*) return 1 ;;
    esac

    if [ -z "$ports" ]; then
        ndmc -c 'ip http port 8080' >/dev/null 2>&1
        ndmc -c 'ip http port 80' >/dev/null 2>&1
        ndmc -c 'system configuration save' >/dev/null 2>&1
        sleep 2
        refresh_port_cache
        ports=$(json_get_ports)
    fi

    [ -n "$ports" ] || return 1

    echo "$ports"
    return 0
}
