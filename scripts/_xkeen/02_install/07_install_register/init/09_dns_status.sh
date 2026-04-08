
# Проверка статуса прокси-клиента
proxy_status() { pidof "$name_client" >/dev/null; }

# Поиск конфигураций DNS
check_dns_config() {
    [ "$proxy_dns" != "on" ] && echo "false" && return

    if [ "$name_client" = "xray" ]; then
        for file in "$directory_xray_config"/*.json; do
            [ -f "$file" ] || continue
            if strip_json_comments "$file" | jq -e '.dns.servers? != null' >/dev/null 2>&1; then
                echo "true"
                return
            fi
        done
    elif [ "$name_client" = "mihomo" ]; then
        if [ -f "$mihomo_config" ] && yq -e '.dns.enable == true' "$mihomo_config" >/dev/null 2>&1; then
            echo "true"
            return
        fi
    fi

    echo "false"
    return
}
file_dns=$(check_dns_config)
