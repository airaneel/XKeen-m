
strip_json_comments() {
    sed -e ':a; s:/\*[^*]*\*[^/]*\*/::g; ta' \
        -e 's/^[[:space:]]*\/\/.*$//' \
        -e 's/[[:space:]]\{1,\}\/\/.*$//' "$@"
}

# Функция валидации xkeen.json
validate_xkeen_json() {
    [ ! -f "$xkeen_config" ] && return 0
    if ! jq -e . "$xkeen_config" >/dev/null 2>&1; then
            log_error_terminal "
  Валидация JSON: файл '${yellow}xkeen.json${reset}' содержит синтаксические ошибки
  Запуск прокси невозможен
"
    fi

    if ! jq -e '.xkeen.policy[]? | .name' "$xkeen_config" >/dev/null 2>&1; then
        if jq -e '.xkeen' "$xkeen_config" >/dev/null 2>&1; then
            log_error_terminal "
  Файл '${yellow}xkeen.json${reset}' имеет неверную структуру
  Запуск прокси невозможен
"
        fi
    fi

    return 0
}

# Функция поиска резервных копий конфигурационных файлов Xray
check_xray_backups() {
    [ "$name_client" != "xray" ] && return 0

    # Ищем json-файлы с типичными признаками копий
    bad_files=$(find "$directory_xray_config" -maxdepth 1 -type f \( -iname "*bak*.json" -o -iname "*old*.json" -o -iname "*copy*.json" -o -iname "*копия*.json" -o -iname "*orig*.json" -o -iname "*save*.json" -o -iname "*temp*.json" -o -iname "*tmp*.json" -o -name "*(*).json" \))

    if [ -n "$bad_files" ]; then
        bad_list=$(echo "$bad_files" | awk -F/ '{print "  - " $NF}')

        log_error_terminal "
  В директории конфигурации Xray найдены резервные копии:
${light_blue}${bad_list}${reset}

  Измените расширение резервных копий, например, на ${yellow}.bak${reset}
  Либо переместите их в поддиректорию
  Запуск ${yellow}$name_client${reset} ${red}отменен${reset}
"
    fi
    return 0
}

# Функция проверки наличия метки 255
validate_routing_mark() {
    [ "$proxy_router" != "on" ] && return 0

    mark_valid="false"
    mark_msg=""
    bad_items=""
    has_items="false"
    all_marks_ok="true"

    if [ "$name_client" = "xray" ]; then
        mark_msg="mark"

        for file in "$directory_xray_config"/*.json; do
            [ -f "$file" ] || continue

            if strip_json_comments "$file" | jq -e '.outbounds != null' >/dev/null 2>&1; then
                has_items="true"

                current_bad=$(strip_json_comments "$file" | jq -r '
                    .outbounds[]? |
                    select(.protocol != "blackhole" and .protocol != "dns") |
                    select(.streamSettings.sockopt.mark != 255) |
                    (.tag // .protocol)
                ')

                if [ -n "$current_bad" ]; then
                     bad_items="${bad_items}${bad_items:+\n}$current_bad"
                    all_marks_ok="false"
                fi
            fi
        done

    elif [ "$name_client" = "mihomo" ]; then
        mark_msg="routing-mark"

        if [ -f "$mihomo_config" ]; then

            if yq -e '.["routing-mark"] == 255' "$mihomo_config" >/dev/null 2>&1; then
                mark_valid="true"
            elif yq -e '
                .proxy-providers[]? |
                select(.override."routing-mark" == 255)
            ' "$mihomo_config" >/dev/null 2>&1; then
                mark_valid="true"
            else

                if yq -e '.proxies != null' "$mihomo_config" >/dev/null 2>&1; then
                    has_items="true"
                    current_bad=$(yq -r '
                        .proxies[]? |
                        select(."routing-mark" != 255) |
                        .name
                    ' "$mihomo_config")

                    if [ -n "$current_bad" ]; then
                        bad_items="${bad_items}${bad_items:+\n}$current_bad"
                        all_marks_ok="false"
                    fi
                fi
            fi
        fi
    fi

    if [ "$mark_valid" != "true" ]; then
        if [ "$has_items" = "true" ] && [ "$all_marks_ok" = "true" ]; then
            mark_valid="true"
        fi
    fi

    if [ "$mark_valid" != "true" ]; then
        error_details=""

        if [ -n "$bad_items" ]; then
            bad_list=$(printf "%b\n" "$bad_items" | awk '!seen[$0]++ {print "  - " $0}')

            if [ "$name_client" = "xray" ]; then
                error_details="
  Подключения без метки:
${light_blue}${bad_list}${reset}"
                proxy_hint="  Добавьте маркировку во ВСЕ исходящие подключения (кроме blackhole и dns)"
            else
                error_details="
  Прокси без метки:
${light_blue}${bad_list}${reset}"
                proxy_hint="  Добавьте в config.yaml маркировку трафика глобально либо в каждое исходящее подключение"
            fi
        fi

        log_warning_terminal "
  Для проксирования трафика Entware требуется его маркировка
  В конфигурации ${yellow}$name_client${reset} параметр ${green}$mark_msg: 255${reset} прописан не везде$error_details

$proxy_hint

  Проксирование трафика Entware ${red}отключено${reset}
"
        proxy_router="off"
    fi

    return 0
}
