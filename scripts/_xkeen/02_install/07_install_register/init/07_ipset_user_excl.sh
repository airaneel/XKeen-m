
# Загружает один ipset из $file_ip_exclude, фильтруя строки переданным regex.
# Используется как для IPv4 (user_exclude), так и для IPv6 (user_exclude6).
load_user_ipset_family() {
    set_name="$1"
    family="$2"
    addr_regex="$3"

    ipset create "$set_name" hash:net family "$family" -exist
    ipset flush "$set_name"
    sed -e 's/\r$//' -e 's/#.*//' -e '/^[[:space:]]*$/d' "$file_ip_exclude" |
    grep -Eo "$addr_regex" |
    awk -v s="$set_name" '{print "add "s" "$1}' | ipset restore -exist
}

# Функция загрузки пользовательских исключений в ipset
load_user_ipset() {
    [ ! -f "$file_ip_exclude" ] && return

    [ "$iptables_supported" = "true" ] && load_user_ipset_family \
        user_exclude inet '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?'

    [ "$ip6tables_supported" = "true" ] && load_user_ipset_family \
        user_exclude6 inet6 '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}(/[0-9]{1,3})?'
}
