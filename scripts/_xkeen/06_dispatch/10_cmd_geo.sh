# Команды для работы с GeoFile/GeoIPSET (без полного цикла -i):
# -g (установить базы), -gips (установить GeoIPSET), -dgips (удалить GeoIPSET).

cmd_install_geo() {
    command -v xray >/dev/null 2>&1 || { echo -e "  ${red}Не обнаружено${reset} ядро проксирования Xray"; exit 1; }
    test_connection
    test_github
    sleep 2

    clear
    info_geosite
    info_geoip

    choice_geosite
    delete_geosite
    install_geosite
    sleep 2

    clear
    choice_geoip
    delete_geoip
    install_geoip
    sleep 2

    clear
    echo
    echo -e "  Установка баз GeoFile ${green}выполнена${reset}"
}

cmd_install_geoipset() {
    test_connection
    test_github

    clear
    install_geoipset init
}

cmd_remove_geoipset() {
    clear
    delete_geoipset
}
