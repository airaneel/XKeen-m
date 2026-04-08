
# Часть 1 hook'а: переменные окружения + базовые helper-функции
# (restart_script, ipt, add_exclude_rules, add_ipset_exclude).
# Открывает блок `if pidof ... ; then` — закрывается в _firewall_emit_dispatch.
_firewall_emit_head() {
    cat <<HOOK_HEAD >> "$file_netfilter_hook"
#!/bin/sh

name_client="$name_client"
name_profile="$name_profile"
mode_proxy="$mode_proxy"
network_redirect="$network_redirect"
network_tproxy="$network_tproxy"
networks="$networks"
name_chain="$name_chain"
port_redirect="$port_redirect"
port_tproxy="$port_tproxy"
port_donor="$port_donor"
port_exclude="$port_exclude"
policy_mark="$policy_mark"
custom_mark="$custom_mark"
dscp_exclude="$dscp_exclude"
dscp_proxy="$dscp_proxy"
user_policies="$user_policies"
table_redirect="$table_redirect"
table_tproxy="$table_tproxy"
table_mark="$table_mark"
table_id="$table_id"
file_dns="$file_dns"
proxy_dns="$proxy_dns"
proxy_router="$proxy_router"
directory_os_modules="$directory_os_modules"
directory_user_modules="$directory_user_modules"
directory_configs_app="$directory_configs_app"
directory_xray_config="$directory_xray_config"
directory_xray_asset="$directory_xray_asset"
iptables_supported="$iptables_supported"
ip6tables_supported="$ip6tables_supported"
arm64_fd="$arm64_fd"
other_fd="$other_fd"
aghfix="$aghfix"

# Перезапуск скрипта
restart_script() {
    exec /bin/sh "\$0" "\$@"
}

if pidof "\$name_client" >/dev/null; then

    ipt() {
        if [ "\$family" = "iptables" ] && [ "\$iptables_supported" = "true" ]; then
            iptables -w -t "\$table" "\$@"
        elif [ "\$family" = "ip6tables" ] && [ "\$ip6tables_supported" = "true" ]; then
            ip6tables -w -t "\$table" "\$@"
        fi
    }

    # Добавление правил-исключений
    add_exclude_rules() {
        chain="\$1"
        for exclude in \$exclude_list; do
            if [ "\$file_dns" = "true" ] && [ "\$proxy_dns" = "on" ] && [ "\$chain" != "\${name_chain}_out" ]; then
                case "\$exclude" in
                    10.0.0.0/8|172.16.0.0/12|192.168.0.0/16|fd00::/8|fe80::/10)
                    if [ "\$table" = "mangle" ] && [ "\$mode_proxy" = "Hybrid" ]; then
                        ipt -A "\$chain" -d "\$exclude" -p tcp --dport 53 -j RETURN >/dev/null 2>&1
                        ipt -A "\$chain" -d "\$exclude" -p udp ! --dport 53 -j RETURN >/dev/null 2>&1
                    elif [ "\$table" = "nat" ] && [ "\$mode_proxy" = "Hybrid" ]; then
                        ipt -A "\$chain" -d "\$exclude" -p tcp ! --dport 53 -j RETURN >/dev/null 2>&1
                        ipt -A "\$chain" -d "\$exclude" -p udp --dport 53 -j RETURN >/dev/null 2>&1
                    elif [ "\$table" = "mangle" ] && [ "\$mode_proxy" = "TProxy" ]; then
                        ipt -A "\$chain" -d "\$exclude" -p tcp ! --dport 53 -j RETURN >/dev/null 2>&1
                        ipt -A "\$chain" -d "\$exclude" -p udp ! --dport 53 -j RETURN >/dev/null 2>&1
                    fi
                    ;;
                esac
            else
                ipt -A "\$chain" -d "\$exclude" -j RETURN >/dev/null 2>&1
            fi
        done
    }

    add_ipset_exclude() {
        base_set="\$1"
        set_type="\${2:-hash:net}"

        if [ "\$family" = "ip6tables" ]; then
            set_name="\${base_set}6"
            ipset_family="inet6"
        else
            set_name="\$base_set"
            ipset_family="inet"
        fi

        ipset create "\$set_name" "\$set_type" family "\$ipset_family" -exist || return

        ipt -C "\$chain" -m set --match-set "\$set_name" dst -j RETURN >/dev/null 2>&1 ||
        ipt -I "\$chain" 1 -m set --match-set "\$set_name" dst -j RETURN >/dev/null 2>&1
    }

HOOK_HEAD
}
