# Удаление отдельных компонентов XKeen: Xray, Mihomo, сам XKeen,
# базы GeoSite, GeoIP. Полное удаление со всем — в 03_cmd_remove_full.sh.

cmd_remove_xray() {
    clear
    echo
    choice_for_remove="Xray"
    choice_remove
    clear
    echo
    command -v xray >/dev/null 2>&1 || { echo -e "  Xray ${red}не установлен${reset}"; exit 1; }
    echo -e "  Удаление ${yellow}Xray${reset}"

    $initd_file stop >/dev/null 2>&1
    opkg remove xray_s
    rm -f "$install_dir/xray"

    echo
    echo -e "  Удаление ${yellow}конфигурационных файлов Xray${reset}"

    delete_configs
    logs_delete_configs_info_console

    echo
    echo -e "  Удаление Xray ${green}выполнено${reset}"
}

cmd_remove_mihomo() {
    clear
    echo
    choice_for_remove="Mihomo"
    choice_remove
    clear
    echo
    command -v mihomo >/dev/null 2>&1 || { echo -e "  Mihomo ${red}не установлен${reset}"; exit 1; }
    echo -e "  Удаление ${yellow}Mihomo${reset}"

    $initd_file stop >/dev/null 2>&1
    opkg remove mihomo_s
    opkg remove yq_s
    rm -f "$install_dir/mihomo" "$install_dir/yq"
    rm -rf "$mihomo_conf_dir"

    echo
    echo -e "  Удаление Mihomo ${green}выполнено${reset}"
}

cmd_remove_xkeen() {
    clear
    echo
    choice_for_remove="XKeen"
    choice_remove

    clear
    echo
    echo -e "  Удаление ${yellow}XKeen${reset}"
    opkg remove xkeen
    delete_tmp

    clear
    echo
    delete_all

    clear
    echo
    echo -e "  Удаление XKeen ${green}выполнено${reset}"
    echo
    echo -e "  Установить ${yellow}XKeen${reset} заново можно командами:"
    echo
    echo -e "  ${green}curl -OL ${xkeen_install_url}${reset}"
    echo -e "  ${green}chmod +x install.sh${reset}"
    echo -e "  ${green}./install.sh${reset}"
}

cmd_remove_geoip() {
    clear
    echo
    choice_for_remove="GeoIP"
    choice_remove

    clear
    echo
    echo -e "  Удаление всех баз ${yellow}GeoIP${reset}"

    delete_geoip_key
    logs_delete_geoip_info_console

    echo
    echo -e "  Удаление всех баз GeoIP ${green}выполнено${reset}"
}

cmd_remove_geosite() {
    clear
    echo
    choice_for_remove="GeoSite"
    choice_remove

    clear
    echo
    echo -e "  Удаление всех баз ${yellow}GeoSite${reset}"

    delete_geosite_key
    logs_delete_geosite_info_console

    echo
    echo -e "  Удаление всех баз GeoSite ${green}выполнено${reset}"
}
