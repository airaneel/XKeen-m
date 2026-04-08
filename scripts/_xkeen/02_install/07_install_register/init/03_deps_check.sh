
for cmd in jq curl grep awk sed ipset; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
         log_error_terminal "Не найдена необходимая утилита: ${yellow}$cmd${reset}"
    fi
done
