# Полная деинсталляция XKeen со всеми зависимостями (-remove).
cmd_remove_full() {
    clear
    echo
    choice_for_remove="XKeen полностью со всеми зависимостями"
    choice_remove

    info_cron
    clear
    echo
    echo -e "  Удаление задачи автообновления баз ${yellow}GeoFile${reset}"
    delete_cron_geofile
    logs_delete_cron_geofile_info_console

    echo
    echo -e "  Удаление задачи автообновления баз GeoFile ${green}выполнено${reset}"
    sleep 2

    # Удаление GeoSite's
    clear
    echo
    echo -e "  Удаление всех баз ${yellow}GeoSite${reset}"

    delete_geosite_key
    logs_delete_geosite_info_console

    echo -e "  Удаление всех баз GeoSite ${green}выполнено${reset}"
    sleep 2

    # Удаление GeoIP's
    clear
    echo
    echo -e "  Удаление всех баз ${yellow}GeoIP${reset}"

    delete_geoip_key
    logs_delete_geoip_info_console

    echo -e "  Удаление всех баз GeoIP ${green}выполнено${reset}"
    sleep 2

    # Удаление GeoIPSET
    clear
    echo
    echo -e "  Удаление ${yellow}GeoIPSET${reset}"

    delete_geoipset_key
    logs_delete_geoipset_info_console

    echo -e "  Удаление GeoIPSET ${green}выполнено${reset}"
    sleep 2

    # Удаление файлов конфигурации Xray
    clear
    echo
    echo -e "  Удаление ${yellow}конфигурационных файлов Xray${reset}"

    delete_configs
    logs_delete_configs_info_console

    echo
    echo -e "  Удаление конфигурационных файлов Xray ${green}выполнено${reset}"
    sleep 2

    # Удаление Xray
    clear
    echo
    echo -e "  ${yellow}Удаление${reset} Xray"

    $initd_file stop >/dev/null 2>&1
    opkg remove xray_s
    rm -f "$install_dir/xray"
    rm -rf "/opt/etc/xray"

    echo
    echo -e "  Удаление Xray ${green}выполнено${reset}"
    sleep 2

    # Удаление Mihomo
    clear
    echo
    echo -e "  ${yellow}Удаление${reset} Mihomo"
    opkg remove mihomo_s
    opkg remove yq_s
    rm -f "$install_dir/mihomo" "$install_dir/yq"
    rm -rf "$mihomo_conf_dir"

    echo
    echo -e "  Удаление Mihomo ${green}выполнено${reset}"
    sleep 2

    # Удаление XKeen
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
    echo -e "  Полная деинсталляция ${yellow}XKeen${reset} и всех зависимостей ${green}выполнена${reset}"
    echo
    echo -e "  Установить ${yellow}XKeen${reset} заново можно командами:"
    echo
    echo -e "  ${green}curl -OL ${xkeen_install_url}${reset}"
    echo -e "  ${green}chmod +x install.sh${reset}"
    echo -e "  ${green}./install.sh${reset}"
}
