
# Удаление правил Iptables
clean_firewall() {
    [ -f "$file_netfilter_hook" ] && : > "$file_netfilter_hook"

    get_ipver_support

    for family in iptables ip6tables; do
        [ "$family" = "iptables" ] && [ "$iptables_supported" != "true" ] && continue
        [ "$family" = "ip6tables" ] && [ "$ip6tables_supported" != "true" ] && continue

        if "$family" -w -t nat -nL _NDM_HOTSPOT_DNSREDIR >/dev/null 2>&1; then
            "$family" -w -t nat -S _NDM_HOTSPOT_DNSREDIR | grep 'REDIRECT --to-ports 53' | grep -- '-m mark --mark' | while IFS= read -r rule; do
                rule=${rule#-A _NDM_HOTSPOT_DNSREDIR }
                "$family" -w -t nat -D _NDM_HOTSPOT_DNSREDIR $rule >/dev/null 2>&1
            done
        fi
    done

    clean_run() {
        family="$1"
        table="$2"
        name_chain="$3"

        if "$family" -w -t "$table" -nL "$name_chain" >/dev/null 2>&1; then
            "$family" -w -t "$table" -F "$name_chain" >/dev/null 2>&1

            while "$family" -w -t "$table" -nL PREROUTING | grep -q "$name_chain"; do
                rule_number=$("$family" -w -t "$table" -nL PREROUTING --line-numbers | grep -m 1 "$name_chain" | awk '{print $1}')
                "$family" -w -t "$table" -D PREROUTING "$rule_number" >/dev/null 2>&1
            done

            "$family" -w -t "$table" -X "$name_chain" >/dev/null 2>&1
        fi

        out_chain="${name_chain}_out"
        if "$family" -w -t "$table" -nL "$out_chain" >/dev/null 2>&1; then
            "$family" -w -t "$table" -F "$out_chain" >/dev/null 2>&1
            while "$family" -w -t "$table" -nL OUTPUT | grep -q "$out_chain"; do
                rule_number=$("$family" -w -t "$table" -nL OUTPUT --line-numbers | grep -m 1 "$out_chain" | awk '{print $1}')
                "$family" -w -t "$table" -D OUTPUT "$rule_number" >/dev/null 2>&1
            done
            "$family" -w -t "$table" -X "$out_chain" >/dev/null 2>&1
        fi

    }

    for family in iptables ip6tables; do
        for chain in nat mangle; do
            clean_run "$family" "$chain" "$name_chain"
            "$family" -t "$chain" -S PREROUTING | grep "multiport" | grep "RETURN" | \
            while read -r rule; do
                rule=${rule#-A PREROUTING }
                "$family" -t $chain -D PREROUTING $rule >/dev/null 2>&1
            done
        done
    done

    if command -v ip >/dev/null 2>&1; then
        for family in 4 6; do
            while ip -"$family" rule del fwmark "$table_mark" lookup "$table_id" >/dev/null 2>&1; do :; done
            ip -"$family" route flush table "$table_id" >/dev/null 2>&1 || true
        done
    fi

    # Очистка и удаление списков ipset
    if command -v ipset >/dev/null 2>&1; then
        for set in geo_exclude geo_exclude6 user_exclude user_exclude6; do
            ipset flush "$set" >/dev/null 2>&1
            ipset destroy "$set" >/dev/null 2>&1
        done
    fi
}
