
# Функция чтения пользовательских портов из файлов
read_ports_from_file() {
    file_ports="$1"
    [ -f "$file_ports" ] || return

    sed -e 's/\r$//' -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$file_ports"
}

# Функция обработки, валидации и нормализации списка портов
validate_and_clean_ports() {
    input_ports="$1"

    echo "$input_ports" | tr ',' '\n' | awk '
        function is_valid(p) {
            return p ~ /^[0-9]+$/ && p > 0 && p <= 65535
        }
        {
            gsub(/[[:space:]]/, "", $0)
            gsub(/-/, ":", $0)
            if ($0 == "") next

            n = split($0, a, ":")

            if (n == 1) {
                if (is_valid(a[1])) {
                    print a[1]
                }
            }

            else if (n == 2) {
                if (is_valid(a[1]) && is_valid(a[2])) {
                    start = a[1]
                    end   = a[2]

                    if (start > end) {
                        tmp = start
                        start = end
                        end = tmp
                    }

                    if (start <= end) {
                        print start ":" end
                    }
                }
            }
        }
    ' | sort -n -u | tr '\n' ',' | sed 's/,$//'
}

# Добавляет порт в начало comma-separated списка, если его там ещё нет.
# Возвращает обновлённый список через stdout.
# Использует tr+grep вместо хитрого regex со всеми разделителями.
prepend_port_if_missing() {
    list="$1"
    port="$2"

    if printf '%s' "$list" | tr ',' '\n' | grep -qx "$port"; then
        printf '%s' "$list"
    else
        printf '%s,%s' "$port" "$list"
    fi
}

# Функция обработки пользовательских портов
process_user_ports() {
    port_donor=$(validate_and_clean_ports "$(read_ports_from_file "$file_port_proxying")")
    port_exclude=$(validate_and_clean_ports "$(read_ports_from_file "$file_port_exclude")")

    if [ -n "$port_donor" ]; then
        port_donor=$(prepend_port_if_missing "$port_donor" 80)
        port_donor=$(prepend_port_if_missing "$port_donor" 443)
    fi

    if [ -n "$port_donor" ] && [ -n "$port_exclude" ]; then
        log_warning_terminal "
  Заданы и порты проксирования, и порты исключения
  Прокси будет запущен на портах проксирования, порты исключения игнорируются
"
        port_exclude=""
    fi
}

# Функция нормализации сторонних политик
process_custom_mark() {
    [ -z "$custom_mark" ] && return

    clean_mark=""
    for mark in $(echo "$custom_mark" | tr ',' ' '); do
        val="${mark#0x}"
        if echo "$val" | grep -Eq '^[0-9a-fA-F]+$'; then
            clean_mark="$clean_mark 0x$val"
        fi
    done

    custom_mark="${clean_mark# }"
}
