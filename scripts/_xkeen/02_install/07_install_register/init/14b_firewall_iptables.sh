
# Часть 2 hook'а: основные функции работы с iptables — add_ipt_rule (создание
# базовой цепи xkeen с правилами для Hybrid/TProxy/Redirect режимов) и
# configure_route (правила маршрутизации с fwmark и копирование таблицы main).
_firewall_emit_iptables() {
    cat <<HOOK_IPTABLES >> "$file_netfilter_hook"
    # Добавление правил iptables
    add_ipt_rule() {
        family="\$1"
        table="\$2"
        chain="\$3"
        shift 3
        [ "\$family" = "iptables" ] && [ "\$iptables_supported" = "false" ] && return
        [ "\$family" = "ip6tables" ] && [ "\$ip6tables_supported" = "false" ] && return

        if ! "\$family" -w -t "\$table" -nL \$chain >/dev/null 2>&1; then
            "\$family" -w -t "\$table" -N \$chain || exit 0

            add_exclude_rules \$chain

            if [ "\$table" = "\$table_tproxy" ]; then
                if [ "\$mode_proxy" = "Hybrid" ]; then
                    set -- -p udp -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
                else
                    set -- -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
                fi
                ipt -C \$chain "\$@" >/dev/null 2>&1 || ipt -I \$chain 1 "\$@" >/dev/null 2>&1
            fi

            case "\$mode_proxy" in
                Hybrid)
                    if [ "\$table" = "\$table_redirect" ]; then
                        ipt -I \$chain 1 -m conntrack --ctstate DNAT -j RETURN >/dev/null 2>&1
                        add_ipset_exclude ext_exclude hash:ip
                        add_ipset_exclude geo_exclude hash:net
                        add_ipset_exclude user_exclude hash:net
                        ipt -A \$chain -p tcp -j REDIRECT --to-port "\$port_redirect" >/dev/null 2>&1
                    else
                        ipt -I \$chain 1 -m conntrack --ctstate DNAT -j RETURN >/dev/null 2>&1
                        add_ipset_exclude ext_exclude hash:ip
                        add_ipset_exclude geo_exclude hash:net
                        add_ipset_exclude user_exclude hash:net
                        ipt -A \$chain -p udp -m socket --transparent -j MARK --set-mark "\$table_mark" >/dev/null 2>&1
                        ipt -A \$chain -p udp -m mark ! --mark 0 -j CONNMARK --save-mark >/dev/null 2>&1
                        ipt -A \$chain -p udp -j TPROXY --on-ip "\$proxy_ip" --on-port "\$port_tproxy" --tproxy-mark "\$table_mark" >/dev/null 2>&1
                    fi
                    ;;
                TProxy)
                    ipt -C \$chain -m conntrack --ctstate DNAT -j RETURN >/dev/null 2>&1 ||
                    ipt -I \$chain 1 -m conntrack --ctstate DNAT -j RETURN >/dev/null 2>&1
                    for net in \$network_tproxy; do
                        add_ipset_exclude ext_exclude hash:ip
                        add_ipset_exclude geo_exclude hash:net
                        add_ipset_exclude user_exclude hash:net
                        ipt -A \$chain -p "\$net" -m socket --transparent -j MARK --set-mark "\$table_mark" >/dev/null 2>&1
                        ipt -A \$chain -p "\$net" -m mark ! --mark 0 -j CONNMARK --save-mark >/dev/null 2>&1
                        ipt -A \$chain -p "\$net" -j TPROXY --on-ip "\$proxy_ip" --on-port "\$port_tproxy" --tproxy-mark "\$table_mark" >/dev/null 2>&1
                    done
                    ;;
                Redirect)
                    ipt -C \$chain -m conntrack --ctstate DNAT -j RETURN >/dev/null 2>&1 ||
                    ipt -I \$chain 1 -m conntrack --ctstate DNAT -j RETURN >/dev/null 2>&1
                    add_ipset_exclude ext_exclude hash:ip
                    add_ipset_exclude geo_exclude hash:net
                    add_ipset_exclude user_exclude hash:net
                    for net in \$network_redirect; do
                        ipt -A \$chain -p "\$net" -j REDIRECT --to-port "\$port_redirect" >/dev/null 2>&1
                    done
                    ;;
                *) exit 0 ;;
            esac

            if [ -n "\$dscp_exclude" ]; then
                for dscp in \$dscp_exclude; do
                    ipt -I \$chain -m dscp --dscp "\$dscp" -j RETURN >/dev/null 2>&1
                done
            fi
        fi
    }

    # Настройка таблицы маршрутов
    configure_route() {
        ip_version="\$1"

        # Определяем таблицу маршрутизации
        if [ -n "\$policy_mark" ]; then
            policy_table=\$(ip rule show | awk -v policy="\$policy_mark" '\$0 ~ policy && /lookup/ && !/blackhole/ {print \$(NF)}' | sed -n '1p')
            source_table="\$policy_table"
        else
            source_table="main"
        fi

        # Проверяем есть ли default маршрут
        check_default() {
            if [ "\$ip_version" = "6" ] && ! ip -6 route show default 2>/dev/null | grep -q .; then
                return 0
            fi
            if [ "\$source_table" = "main" ]; then
                ip -\$ip_version route show default 2>/dev/null | grep -q '^default'
            else
                ip -\$ip_version route show table all 2>/dev/null | grep -E "^[[:space:]]*default .* table \$policy_table([[:space:]]|$)" | grep -vq 'unreachable' >/dev/null
            fi
        }

        attempts=0
        max_attempts=4
        until check_default; do
            attempts=\$((attempts + 1))
            if [ "\$attempts" -ge "\$max_attempts" ]; then
                [ "\$ip_version" = "4" ] && touch "/tmp/noinet"
                return 1
            fi
            sleep 1
        done
        [ "\$ip_version" = "4" ] && rm -f "/tmp/noinet"

        ip -\$ip_version rule del fwmark \$table_mark lookup \$table_id >/dev/null 2>&1 || true
        ip -\$ip_version route flush table \$table_id >/dev/null 2>&1 || true
        ip -\$ip_version route add local default dev lo table \$table_id >/dev/null 2>&1 || true
        ip -\$ip_version rule add fwmark \$table_mark lookup \$table_id >/dev/null 2>&1 || true

        # Копируем маршруты
        ip -\$ip_version route show table \$source_table 2>/dev/null | while read -r route_line; do
            case "\$route_line" in
                default*|unreachable*|blackhole*) continue ;;
                *) ip -\$ip_version route add table \$table_id \$route_line >/dev/null 2>&1 || true ;;
            esac
        done
        return 0
    }

HOOK_IPTABLES
}
