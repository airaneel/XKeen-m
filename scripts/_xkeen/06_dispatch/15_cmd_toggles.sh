# Переключатели/тоглы конфигурации XKeen и выбора ядра.
# Каждая команда — тонкий wrapper над функцией change_*. Не имеют логики
# сами по себе, кроме clear перед вызовом.

cmd_change_channel() {
    clear
    choice_channel_xkeen
    change_channel_xkeen
}

cmd_use_xray() {
    choice_xray_core
}

cmd_use_mihomo() {
    choice_mihomo_core
}

cmd_toggle_ipv6() {
    clear
    change_ipv6_support
}

cmd_toggle_dns() {
    clear
    warn_proxy_dns
    change_proxy_dns
}

cmd_toggle_router_proxy() {
    clear
    change_proxy_router
}

cmd_toggle_extmsg() {
    clear
    change_extended_msg
}

cmd_toggle_backup() {
    clear
    change_backup_xkeen
}

cmd_toggle_aghfix() {
    clear
    change_aghfix_xkeen
}
