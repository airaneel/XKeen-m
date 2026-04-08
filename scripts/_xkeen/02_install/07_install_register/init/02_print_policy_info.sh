
print_policy_info() {
    found="$1"
    has_custom="$2"
    ignored_custom="$3"

    ignore_line=""
    if [ "$ignored_custom" = "yes" ]; then
        ignore_line="
  Пользовательские политики из '${yellow}xkeen.json${reset}' будут проигнорированы"
    fi

    if [ "$extended_msg" != "on" ]; then
        if [ "$found" = "no" ]; then
            log_info_terminal "
  Политика '${yellow}$name_policy${reset}' не найдена в веб-интерфейсе роутера${ignore_line}
  Прокси будет запущен для всего устройства
"
        fi
        return
    fi

    if [ "$found" = "yes" ]; then

        if [ "$has_custom" = "yes" ]; then
            custom_names=$(echo "$user_policies" | cut -d'|' -f1 | tr '\n' ',' | sed 's/,$//; s/,/, /g')
            policies="${name_policy}, ${custom_names}"

            detail_list=""
            if [ -n "$port_donor" ]; then
                detail_list="  - ${yellow}$name_policy${reset} на портах ${green}${port_donor}${reset}"
            elif [ -n "$port_exclude" ]; then
                detail_list="  - ${yellow}$name_policy${reset} на всех портах кроме ${green}${port_exclude}${reset}"
            else
                detail_list="  - ${yellow}$name_policy${reset} на всех портах"
            fi

            custom_details=$(echo "$user_policies" | while IFS='|' read -r p_name p_mark p_mode p_ports; do
                if [ "$p_mode" = "include" ]; then
                    echo "  - ${yellow}$p_name${reset} на портах ${green}${p_ports}${reset}"
                elif [ "$p_mode" = "exclude" ]; then
                    echo "  - ${yellow}$p_name${reset} на всех портах кроме ${green}${p_ports}${reset}"
                else
                    echo "  - ${yellow}$p_name${reset} на всех портах"
                fi
            done)

            log_info_terminal "
  Найдены политики '${yellow}${policies}${reset}'
  Прокси будет запущен для клиентов политик:
${detail_list}
${custom_details}
"
        else
            if [ -z "$port_donor" ] && [ -z "$port_exclude" ]; then
                log_info_terminal "
  Найдена политика '${yellow}$name_policy${reset}'
  Не определены целевые порты для XKeen
  Прокси будет запущен для клиентов политики '${yellow}$name_policy${reset}' на всех портах
"
            elif [ -n "$port_donor" ]; then
                log_info_terminal "
  Найдена политика '${yellow}$name_policy${reset}'
  Определены целевые порты для XKeen
  Прокси будет запущен для клиентов политики '${yellow}$name_policy${reset}'
  на портах ${green}${port_donor}${reset}
"
            else
                log_info_terminal "
  Найдена политика '${yellow}$name_policy${reset}'
  Определены порты исключения для XKeen
  Прокси будет запущен для клиентов политики '${yellow}$name_policy${reset}'
  на всех портах кроме ${green}${port_exclude}${reset}
"
            fi
        fi
    else
        if [ -n "$port_donor" ]; then
            log_info_terminal "
  Политика '${yellow}$name_policy${reset}' не найдена в веб-интерфейсе роутера${ignore_line}
  Определены целевые порты для XKeen
  Прокси будет запущен для всех клиентов
  на портах ${green}${port_donor}${reset}
"
        elif [ -n "$port_exclude" ]; then
            log_info_terminal "
  Политика '${yellow}$name_policy${reset}' не найдена в веб-интерфейсе роутера${ignore_line}
  Определены порты исключения для XKeen
  Прокси будет запущен для всех клиентов
  на всех портах кроме ${green}${port_exclude}${reset}
"
        else
            log_info_terminal "
  Политика '${yellow}$name_policy${reset}' не найдена в веб-интерфейсе роутера${ignore_line}
  Не определены целевые порты для XKeen
  Прокси будет запущен для всех клиентов на всех портах
"
        fi
    fi
}
