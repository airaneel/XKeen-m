# Резервное копирование и восстановление XKeen, конфигов Xray и Mihomo.
# 6 команд: -kb / -kbr / -xb / -xbr / -mb / -mbr.

cmd_backup_xkeen() {
    echo -e "  Создание резервной копии ${yellow}XKeen${reset}"
    info_version_xkeen
    manual_backup="on"
    backup_xkeen
}

cmd_restore_xkeen() {
    echo -e "  Восстановление ${yellow}XKeen${reset} из резервной копии"
    restore_backup_xkeen
}

cmd_backup_xray() {
    command -v xray >/dev/null 2>&1 || { echo -e "  ${red}Не обнаружено${reset} ядро проксирования Xray"; exit 1; }
    echo -e "  Создание резервной копии ${yellow}конфигурации Xray${reset}"
    backup_configs_xray
}

cmd_restore_xray() {
    command -v xray >/dev/null 2>&1 || { echo -e "  ${red}Не обнаружено${reset} ядро проксирования Xray"; exit 1; }
    echo -e "  Восстановление ${yellow}конфигурации Xray${reset} из резервной копии"
    restore_backup_configs_xray
}

cmd_backup_mihomo() {
    command -v mihomo >/dev/null 2>&1 || { echo -e "  ${red}Не обнаружено${reset} ядро проксирования Mihomo"; exit 1; }
    echo -e "  Создание резервной копии ${yellow}конфигурации Mihomo${reset}"
    backup_configs_mihomo
}

cmd_restore_mihomo() {
    command -v mihomo >/dev/null 2>&1 || { echo -e "  ${red}Не обнаружено${reset} ядро проксирования Mihomo"; exit 1; }
    echo -e "  Восстановление ${yellow}конфигурации Mihomo${reset} из резервной копии"
    restore_backup_configs_mihomo
}
