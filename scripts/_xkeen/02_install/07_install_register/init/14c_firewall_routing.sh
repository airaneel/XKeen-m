
# Часть 3 hook'а: PREROUTING-логика — flush_xkeen_rules (снос накопленных
# правил), add_multiport_rules (батчевая вставка multiport), add_prerouting
# (главная сборка цепочек по политикам и портам).
_firewall_emit_routing() {
    cat <<HOOK_ROUTING >> "$file_netfilter_hook"
    # Снос всех правил xkeen из PREROUTING (mangle/nat) для текущей family
    # Нужно ПЕРЕД add_prerouting, чтобы избежать накопления правил со старыми
    # списками портов после изменения policy/port_exclude/port_donor.
    # ipt -C идемпотентен только для одного и того же набора аргументов.
    # Чистит правила xkeen ТОЛЬКО для текущей \$table.
    # add_prerouting вызывается отдельно для mangle и nat — каждый вызов
    # должен сносить только правила своей таблицы. Старая версия чистила
    # обе таблицы за один вызов и удаляла результат предыдущего вызова
    # (например, mangle создавал udp/connmark правило, а следующий вызов
    # add_prerouting для nat его сразу же сносил через flush).
    flush_xkeen_rules() {
        ipt -S PREROUTING 2>/dev/null | grep -E -- "-j (\$name_chain|RETURN)\$" |
            grep -E -- "(--mark \$policy_mark|--mark 0x[0-9a-fA-F]+ .* -j (\$name_chain|RETURN)\$|^-A PREROUTING -m conntrack ! --ctstate INVALID .* -j \$name_chain\$)" |
            sed 's/^-A /-D /' | while IFS= read -r _r; do
                [ -n "\$_r" ] && ipt \$_r >/dev/null 2>&1
            done
    }

    # Создание множественных правил multiport
    add_multiport_rules() {
        family="\$1"
        table="\$2"
        net="\$3"
        mark="\$4"
        ports="\$5"
        target="\$6"

        [ -z "\$ports" ] && return

        num_ports=\$(echo "\$ports" | tr ',' '\n' | wc -l)
        i=1
        while [ "\$i" -le "\$num_ports" ]; do
            end=\$((i + 6))
            chunk=\$(echo "\$ports" | tr ',' '\n' | sed -n "\${i},\${end}p" | tr '\n' ',' | sed 's/,$//')
            [ -z "\$chunk" ] && break
            if [ -n "\$mark" ]; then
                set -- -m connmark --mark "\$mark" -m conntrack ! --ctstate INVALID -p "\$net" -m multiport --dports "\$chunk" -j "\$target"
            else
                set -- -m conntrack ! --ctstate INVALID -p "\$net" -m multiport --dports "\$chunk" -j "\$target"
            fi
            ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
            i=\$((i + 7))
        done
    }

    # Добавление цепочек PREROUTING
    add_prerouting() {
        family="\$1"
        table="\$2"

        # Снос накопленных правил перед добавлением новых (фикс accumulation bug)
        flush_xkeen_rules

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

            for dscp in \$dscp_proxy; do
                set -- -m conntrack ! --ctstate INVALID \$proto_match -m dscp --dscp "\$dscp" -j "\$name_chain"
                ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
            done

            if [ "\$proxy_router" = "on" ]; then
                set -- -i lo -m mark --mark "\$table_mark" \$proto_match -j "\$name_chain"
                ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
            fi

            # Пользовательские политики из xkeen.json
            echo "\$user_policies" | while IFS='|' read -r pname pmark pmode pports; do
                [ -z "\$pmark" ] && continue

                pmark=\$(echo "\$pmark" | tr -d ' \r\n')
                pmode=\$(echo "\$pmode" | tr -d ' \r\n')
                pports=\$(echo "\$pports" | tr -d ' \r\n')

                if [ "\$pmode" = "all" ]; then
                    set -- -m connmark --mark 0x"\$pmark" -m conntrack ! --ctstate INVALID -j "\$name_chain"
                    ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
                elif [ "\$pmode" = "include" ]; then
                    add_multiport_rules "\$family" "\$table" "\$net" "0x\$pmark" "\$pports" "\$name_chain"
                elif [ "\$pmode" = "exclude" ]; then
                    add_multiport_rules "\$family" "\$table" "\$net" "0x\$pmark" "\$pports" "RETURN"
                    set -- -m connmark --mark 0x"\$pmark" -m conntrack ! --ctstate INVALID -p "\$net" -j "\$name_chain"
                    ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
                fi
            done

            # Политика xkeen (стандартная)
            if [ -n "\$policy_mark" ]; then
                # заданы порты проксирования
                if [ -n "\$port_donor" ]; then
                    add_multiport_rules "\$family" "\$table" "\$net" "\$policy_mark" "\$port_donor" "\$name_chain"
                # заданы порты исключения
                elif [ -n "\$port_exclude" ]; then
                    add_multiport_rules "\$family" "\$table" "\$net" "\$policy_mark" "\$port_exclude" "RETURN"
                    set -- -m connmark --mark "\$policy_mark" -m conntrack ! --ctstate INVALID -p "\$net" -j "\$name_chain"
                    ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
                else
                    # Политика xkeen, когда порты не указаны (проксирование на всех портах)
                    set -- -m connmark --mark "\$policy_mark" -m conntrack ! --ctstate INVALID -j "\$name_chain"
                    ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
                fi
            # НЕТ политики xkeen
            else
                # заданы порты проксирования
                if [ -n "\$port_donor" ]; then
                    add_multiport_rules "\$family" "\$table" "\$net" "" "\$port_donor" "\$name_chain"
                # заданы порты исключения
                elif [ -n "\$port_exclude" ]; then
                    add_multiport_rules "\$family" "\$table" "\$net" "" "\$port_exclude" "RETURN"
                    set -- -m conntrack ! --ctstate INVALID -p "\$net" -j "\$name_chain"
                    ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
                # Если нет ни xkeen, ни пользовательских политик -> перехватываем всё
                else
                    set -- -m conntrack ! --ctstate INVALID -j "\$name_chain"
                    ipt -C PREROUTING "\$@" >/dev/null 2>&1 || ipt -A PREROUTING "\$@" >/dev/null 2>&1
                fi
            fi
        done
    }

HOOK_ROUTING
}
