
# Функции журналирования
log_info_router() {
    logger -p notice -t "$name_app" "$1"
}

log_warning_router() {
    logger -p warning -t "$name_app" "$1"
}

log_error_router() {
    logger -p error -t "$name_app" "$1"
}

log_info_terminal() {
    echo
    echo -e "${green}Информация${reset}: $1" >&2
}

log_warning_terminal() {
    echo
    echo -e "${yellow}Предупреждение${reset}: $1" >&2
}

log_error_terminal() {
    echo
    echo -e "${red}Ошибка${reset}: $1" >&2
    exit 1
}
