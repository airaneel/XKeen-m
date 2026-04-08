
# Получение порта для Redirect
get_port_redirect() {
    if [ "$name_client" = "mihomo" ]; then
        port=$(yq eval '.redir-port // ""' "$mihomo_config" 2>/dev/null)
        [ -n "$port" ] && echo "$port" && return 0
    else
        port=$(get_xray_port_by_mode "redirect")
        [ -n "$port" ] && echo "$port" && return 0
    fi

    echo ""
}

# Получение порта для TProxy
get_port_tproxy() {
    if [ "$name_client" = "mihomo" ]; then
        port=$(yq eval '.tproxy-port // ""' "$mihomo_config" 2>/dev/null)
        if [ -z "$port" ]; then
            port=$(yq eval '.listeners[] | select(.name == "tproxy" ) | .port // ""' "$mihomo_config" 2>/dev/null)
        fi
        [ -n "$port" ] && echo "$port" && return 0
    else
        port=$(get_xray_port_by_mode "tproxy")
        [ -n "$port" ] && echo "$port" && return 0
    fi

    echo ""
}

# Получение сети для Redirect
get_network_redirect() {
    if [ "$name_client" = "mihomo" ]; then
        [ -n "$port_redirect" ] && echo "tcp" && return 0
        echo "" && return 0
    else
        network=$(get_xray_network_by_mode "redirect")
        [ -n "$network" ] && echo "$network" && return 0
        echo "" && return 0
    fi
}

# Получение сети для TProxy
get_network_tproxy() {
    if [ "$name_client" = "mihomo" ]; then
        if [ -n "$port_redirect" ] && [ -n "$port_tproxy" ]; then
            echo "udp"
        elif [ -z "$port_redirect" ] && [ -n "$port_tproxy" ]; then
            echo "tcp udp"
        else
            echo ""
        fi
        return 0
    else
        network=$(get_xray_network_by_mode "tproxy")
        [ -n "$network" ] && echo "$network" && return 0
        echo "" && return 0
    fi
}

# Получение исключенных портов
# Используется .port (внешний/слушающий порт) вместо .to-port (внутренний/destination
# при пробросе) — пакеты на роутере матчатся по dport входящего, а не по тому
# куда они в итоге будут проброшены. Игнорирует записи с disable=true.
# Удаляет дубликаты, сортирует численно. Защищает от двойного добавления при
# объединении с пользовательским port_exclude.
get_port_exclude() {
    if [ -n "$api_static_json" ]; then
        port_exclude_redirect=$(echo "$api_static_json" | jq -r '.[] | select((.disable // false) | not) | .port' 2>/dev/null |
            grep -E -v '^(80|443)$' | sort -u -n | tr '\n' ',' | sed 's/,$//')
    fi
    if [ -n "$port_exclude" ]; then
        port_exclude="$port_exclude,$port_exclude_redirect"
    else
        port_exclude="$port_exclude_redirect"
    fi
    # Нормализация: только цифры/запятые/двоеточия, схлопнуть запятые,
    # удалить дубликаты с сохранением первого вхождения
    port_exclude=$(echo "$port_exclude" | tr -dc '0-9,:' | sed 's/,,*/,/g; s/^,//; s/,$//' |
        awk -v RS=',' 'NF && !seen[$0]++' | tr '\n' ',' | sed 's/,$//')
    echo "$port_exclude"
}

# Получение исключений IPv4
get_exclude_ip4() {
    [ "$iptables_supported" != "true" ] && return

    # Получаем провайдерский IPv4
    ipv4_eth=$(ip route get 195.208.4.1 2>/dev/null | grep -o 'src [0-9.]\+' | awk '{print $2}' ||
               ip route get 77.88.8.8 2>/dev/null | grep -o 'src [0-9.]\+' | awk '{print $2}')
    [ -n "$ipv4_eth" ] && ipv4_eth="${ipv4_eth}/32"
    echo "${ipv4_eth} ${ipv4_exclude}" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ' | sed 's/^ //; s/ $//'
}

# Получение исключений IPv6
get_exclude_ip6() {
    [ "$ip6tables_supported" != "true" ] && return

    # Получаем провайдерский IPv6
    ipv6_eth=$(ip -6 route get 2a0c:a9c7:8::1 2>/dev/null | awk -F 'src ' '{print $2}' | awk '{print $1}' ||
               ip -6 route get 2a02:6b8::feed:0ff 2>/dev/null | awk -F 'src ' '{print $2}' | awk '{print $1}')
    [ -n "$ipv6_eth" ] && ipv6_eth="${ipv6_eth}/128"
    echo "${ipv6_eth} ${ipv6_exclude}" | tr ' ' '\n' | awk '!seen[$0]++' | tr '\n' ' ' | sed 's/^ //; s/ $//'
}

# Получение метки политики
get_policy_mark() {
    if [ -n "$api_policy_json" ]; then
        policy_mark=$(echo "$api_policy_json" | jq -r --arg pname "$name_policy" '.[] | select(.description | ascii_downcase == ($pname | ascii_downcase)) | .mark' 2>/dev/null)
    fi

    if [ -n "$policy_mark" ]; then
        echo "0x${policy_mark}"
    else
        echo ""
    fi
}
