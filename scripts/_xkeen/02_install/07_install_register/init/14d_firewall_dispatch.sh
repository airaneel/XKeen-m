
# Часть 4 hook'а: add_output (проксирование Entware), dns_redir, главный
# цикл `for family in iptables ip6tables`, recovery-ветка `else` (запуск
# прокси-бинарника при холодном старте) и закрывающий `fi` для блока,
# открытого в _firewall_emit_head.
_firewall_emit_dispatch() {
    cat <<HOOK_DISPATCH >> "$file_netfilter_hook"
    # Добавление цепочек для проксирования трафика Entware
    add_output() {
        family="\$1"
        table="\$2"

        [ "\$proxy_router" != "on" ] && return

        out_chain="\${name_chain}_out"

        if ! "\$family" -w -t "\$table" -nL "\$out_chain" >/dev/null 2>&1; then
            "\$family" -w -t "\$table" -N "\$out_chain" || return

            orig_chain="\$chain"
            chain="\$out_chain"

            ipt -A "\$out_chain" -o lo -j RETURN >/dev/null 2>&1
            ipt -A "\$out_chain" -m mark --mark 255 -j RETURN >/dev/null 2>&1

            add_exclude_rules "\$out_chain"

            add_ipset_exclude ext_exclude hash:ip
            add_ipset_exclude geo_exclude hash:net
            add_ipset_exclude user_exclude hash:net

            chain="\$orig_chain"
        fi

        for net in \$networks; do
            if [ "\$mode_proxy" = "Hybrid" ]; then
                [ "\$table" = "nat"    ] && [ "\$net" != "tcp" ] && continue
                [ "\$table" = "mangle" ] && [ "\$net" != "udp" ] && continue
            fi

            if [ "\$mode_proxy" = "TProxy" ]; then
                proto_match=""
            else
                proto_match="-p \$net"
            fi

            set -- -m conntrack ! --ctstate INVALID \$proto_match -j "\$out_chain"
            ipt -C OUTPUT "\$@" >/dev/null 2>&1 || ipt -A OUTPUT "\$@" >/dev/null 2>&1

            if [ "\$table" = "\$table_redirect" ]; then
                set -- -p "\$net" -j REDIRECT --to-port "\$port_redirect"
                ipt -C "\$out_chain" "\$@" >/dev/null 2>&1 || ipt -A "\$out_chain" "\$@" >/dev/null 2>&1
            elif [ "\$table" = "\$table_tproxy" ]; then
                set -- -p "\$net" -j MARK --set-mark "\$table_mark"
                ipt -C "\$out_chain" "\$@" >/dev/null 2>&1 || ipt -A "\$out_chain" "\$@" >/dev/null 2>&1
            fi
        done
    }

    dns_redir() {
        family="\$1"
        table="nat"

        [ "\$aghfix" != "on" ] && return
        [ "\$file_dns" = "true" ] && [ "\$proxy_dns" = "on" ] && return

        all_marks=""
        [ -n "\$policy_mark" ] && all_marks="\$policy_mark"

        [ -n "\$custom_mark" ] && all_marks="\$custom_mark \$all_marks"

        if [ -n "\$user_policies" ]; then
            user_marks=\$(echo "\$user_policies" | awk -F'|' '{if (\$2 != "") print "0x"\$2}')
            all_marks="\$all_marks \$user_marks"
        fi

        for mark in \$all_marks; do
            mark=\$(echo "\$mark" | tr -d ' \r\n')
            [ -z "\$mark" ] && continue

            for proto in udp tcp; do
                set -- -p "\$proto" -m mark --mark "\$mark" -m pkttype --pkt-type unicast -m "\$proto" --dport 53 -j REDIRECT --to-ports 53
                ipt -C _NDM_HOTSPOT_DNSREDIR "\$@" >/dev/null 2>&1 || ipt -I _NDM_HOTSPOT_DNSREDIR "\$@" >/dev/null 2>&1
            done
        done
    }

    if [ -n "\$port_donor" ] || [ -n "\$port_exclude" ]; then
        [ "\$file_dns" = "true" ] && [ "\$proxy_dns" = "on" ] && [ -n "\$port_donor" ] && port_donor="53,\$port_donor"
    fi
    for family in iptables ip6tables; do
        if [ "\$family" = "ip6tables" ]; then
            exclude_list="$(get_exclude_ip6)"
            proxy_ip="$ipv6_proxy"
            configure_route 6
        else
            exclude_list="$(get_exclude_ip4)"
            proxy_ip="$ipv4_proxy"
            configure_route 4
        fi
        if [ -n "\$port_redirect" ] && [ -n "\$port_tproxy" ]; then
            for table in "\$table_tproxy" "\$table_redirect"; do
                add_ipt_rule "\$family" "\$table" "\$name_chain"
                add_prerouting "\$family" "\$table"
                add_output "\$family" "\$table"
            done
        elif [ -z "\$port_redirect" ] && [ -n "\$port_tproxy" ]; then
            table="\$table_tproxy"
            add_ipt_rule "\$family" "\$table" "\$name_chain"
            add_prerouting "\$family" "\$table"
            add_output "\$family" "\$table"
        elif [ -n "\$port_redirect" ] && [ -z "\$port_tproxy" ]; then
            table="\$table_redirect"
            add_ipt_rule "\$family" "\$table" "\$name_chain"
            add_prerouting "\$family" "\$table"
            add_output "\$family" "\$table"
        fi

        dns_redir "\$family"
    done
else
    [ -f "/tmp/xkeen_starting.lock" ] && exit 0
    touch "/tmp/xkeen_starting.lock"
    . "/opt/sbin/.xkeen/01_info/03_info_cpu.sh"
    status_file="/opt/lib/opkg/status"
    info_cpu

    fd_limit="\$other_fd"
    [ "\$architecture" = "arm64-v8a" ] && fd_limit="\$arm64_fd"
    ulimit -SHn "\$fd_limit"

    case "\$name_client" in
        xray)
            export XRAY_LOCATION_CONFDIR="\$directory_xray_config"
            export XRAY_LOCATION_ASSET="\$directory_xray_asset"
            "\$name_client" run >/dev/null 2>&1 &
        ;;
        mihomo)
            export CLASH_HOME_DIR="\$directory_configs_app"
            "\$name_client" >/dev/null 2>&1 &
        ;;
    esac
    sleep 5
    rm -f "/tmp/xkeen_starting.lock"
    if pidof "\$name_client" >/dev/null; then
        restart_script "\$@"
    else
        exit 1
    fi
fi
HOOK_DISPATCH
}
