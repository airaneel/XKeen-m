# Прочие команды: задержка автозапуска, диагностика, информационные экраны,
# obsolete-команды модулей, default branch для неизвестных ключей.

cmd_set_delay() {
    delay_autostart "$1"
    add_chmod_init
}

cmd_diagnostic() {
    location_entware_storage
    clear
    diagnostic
}

cmd_modules_obsolete() {
    clear
    echo
    migration_modules
}

cmd_modules_remove_obsolete() {
    clear
    echo
    remove_modules
}

cmd_about() {
    clear
    about_xkeen
}

cmd_donate() {
    clear
    author_donate
}

cmd_feedback() {
    clear
    author_feedback
}

cmd_help() {
    clear
    help_xkeen
}

cmd_version() {
    echo "  Версия XKeen $xkeen_current_version $xkeen_build (время сборки: $build_timestamp)"
}

cmd_toff_noop() {
    # -toff обрабатывается ДО входа в while-loop (touch /tmp/toff в начале xkeen).
    # Здесь — пустой no-op чтобы case не выпал в default branch.
    :
}

cmd_unknown() {
    echo -e "     Неизвестный ключ: ${red}$1${reset}"
    echo -e "     Список доступных ключей: ${yellow}xkeen -h${reset}"
}
