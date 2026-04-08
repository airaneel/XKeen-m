
# Получение transparent inbound'ов Xray
get_xray_transparent_inbounds() {
    for file in "$directory_xray_config"/*.json; do
        [ -f "$file" ] || continue

        strip_json_comments "$file" |
        jq -r --arg file "$file" '
            .inbounds[]? |
            select(
                (.protocol == "dokodemo-door" or .protocol == "tunnel") and
                ((.settings.followRedirect? // false) == true)
            ) |
            (.streamSettings.sockopt.tproxy? // "") as $tproxy |
            select($tproxy == "" or $tproxy == "redirect" or $tproxy == "tproxy") |
            [
                (if $tproxy == "tproxy" then "tproxy" else "redirect" end),
                (.port // ""),
                (.settings.network // ""),
                (.tag // ""),
                $file
            ] | @tsv
        ' 2>/dev/null
    done
}

get_xray_port_by_mode() {
    mode="$1"
    port=$(
        get_xray_transparent_inbounds |
        awk -F '\t' -v mode="$mode" '
            $1 == mode && $2 != "" {
                print $2
                exit
            }
        '
    )

    echo "$port"
}

get_xray_network_by_mode() {
    mode="$1"
    network=$(
        get_xray_transparent_inbounds |
        awk -F '\t' -v mode="$mode" '
            function add_networks(value, count, i, item) {
                gsub(/,/, " ", value)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                if (value == "") {
                    return
                }

                count = split(value, items, /[[:space:]]+/)
                for (i = 1; i <= count; i++) {
                    item = items[i]
                    if (item != "" && !seen[item]++) {
                        order[++order_count] = item
                    }
                }
            }

            $1 == mode {
                add_networks($3)
            }

            END {
                for (i = 1; i <= order_count; i++) {
                    printf "%s%s", order[i], (i < order_count ? " " : "")
                }
            }
        '
    )

    echo "$network"
}
