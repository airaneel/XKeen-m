
# Настройка брандмауэра.
# Сборка netfilter hook'а разделена на 4 части, каждая в своём модуле:
#   _firewall_emit_head     — переменные окружения, restart_script, ipt, add_exclude_rules, add_ipset_exclude
#   _firewall_emit_iptables — add_ipt_rule, configure_route
#   _firewall_emit_routing  — flush_xkeen_rules, add_multiport_rules, add_prerouting
#   _firewall_emit_dispatch — add_output, dns_redir, главный цикл, recovery-ветка
# Каждая функция дописывает свой кусок в $file_netfilter_hook через cat <<HEREDOC >>.
# Орchestrator'у важно truncate'ить файл перед первой записью (: > ...).
configure_firewall() {
    : > "$file_netfilter_hook"
    _firewall_emit_head
    _firewall_emit_iptables
    _firewall_emit_routing
    _firewall_emit_dispatch
    chmod +x "$file_netfilter_hook"
    sh "$file_netfilter_hook"
}
