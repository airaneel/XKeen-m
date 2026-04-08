# Обновление установленных баз GeoFile/GeoIPSET (-ug).
cmd_update_geo() {
    test_connection
    test_github
    sleep 2

    clear
    echo
    echo "  Обновление установленных баз GeoFile/GeoIPSET"
    info_geosite
    info_geoip
    if
        [ "$update_refilter_geosite" = "true" ] || \
        [ "$update_v2fly_geosite" = "true" ] || \
        [ "$update_zkeen_geosite" = "true" ] || \
        [ "$update_refilter_geoip" = "true" ] || \
        [ "$update_v2fly_geoip" = "true" ] || \
        [ "$update_zkeenip_geoip" = "true" ]; then

        echo
        install_geosite
        install_geoip
        install_geoipset update

        if pidof xray >/dev/null; then
            $initd_file restart on >/dev/null 2>&1
        fi

        echo -e "  Обновление установленных баз GeoFile/GeoIPSET ${green}завершено${reset}"
    else
        echo -e "  ${red}Не обнаружены${reset} базы GeoFile/GeoIPSET для обновления"
    fi
}
