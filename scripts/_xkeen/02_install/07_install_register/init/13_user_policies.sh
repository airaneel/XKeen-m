
# Получаем пользовательские политики
get_user_policies() {
    [ ! -f "$xkeen_config" ] && return
    jq -r '.xkeen.policy[]? | "\(.name)|\(.port // "")" ' "$xkeen_config" 2>/dev/null
}

# Проверка на конфликт имен политик
check_policy_name_conflict() {
    if [ -f "$xkeen_config" ]; then
        conflict=$(jq -r --arg main "$name_policy" '.xkeen.policy[] | select((.name | ascii_downcase) == ($main | ascii_downcase)) | .name' "$xkeen_config" 2>/dev/null | head -n 1)

        if [ -n "$conflict" ]; then
            log_error_router "Ошибка конфигурации: Имя политики в xkeen.json совпадает с системным"
            log_error_terminal "
  В файле '${yellow}xkeen.json${reset}' найдена политика с именем '${red}${conflict}${reset}'
  Это имя зарезервировано основной службой XKeen

  Переименуйте пользовательскую политику в json-файле
  Запуск ${yellow}$name_client${reset} ${red}отменен${reset}
"
        fi
    fi
}

# Получаем порты пользовательских политик
resolve_user_policies() {
    get_user_policies | while IFS='|' read -r pname pports; do
        if [ -n "$api_policy_json" ]; then
            mark=$(echo "$api_policy_json" | jq -r --arg pname "$pname" '.[] | select(.description | ascii_downcase == ($pname | ascii_downcase)) | .mark' 2>/dev/null | head -n 1)
        fi

        [ -z "$mark" ] && continue

        if [ -z "$pports" ]; then
            # Порты не указаны -> режим "all" (все порты)
            mode="all"
            clean_ports=""
        else
            case "$pports" in
                !*)
                    mode="exclude"
                    ports="${pports#!}"
                    ;;
                *)
                    mode="include"
                    ports="$pports"
                    ;;
            esac

            if [ "$file_dns" = "true" ] && [ "$proxy_dns" = "on" ] && [ "$mode" = "include" ]; then
                echo "$ports" | tr ',' '\n' | grep -q '^53$' || ports="53,$ports"
            fi

            clean_ports=$(validate_and_clean_ports "$ports")
            [ -z "$clean_ports" ] && continue
        fi

        echo "${pname}|${mark}|${mode}|${clean_ports}"
    done
}

# Получение режима прокси-клиента
get_mode_proxy() {
    if [ -n "$port_redirect" ] && [ -n "$port_tproxy" ]; then
        mode_proxy="Hybrid"
    elif [ -n "$port_tproxy" ]; then
        mode_proxy="TProxy"
    elif [ -n "$port_redirect" ]; then
        mode_proxy="Redirect"
    else
        mode_proxy="Other"
    fi
    echo "$mode_proxy"
}
