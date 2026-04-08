# Функция для установки Mihomo
install_mihomo() {
    echo -e "  ${yellow}Выполняется установка${reset} Mihomo. Пожалуйста, подождите..."

    # Определение переменных
    mihomo_archive="${mtmp_dir}/mihomo.gz"

    # Проверка наличия архива Mihomo
    if [ ! -f "${mihomo_archive}" ]; then
        echo -e "  ${red}Ошибка${reset}: Архив Mihomo не найден в '${mtmp_dir}'"
        return 1
    fi

    if [ -f "$install_dir/mihomo" ]; then
        mv "$install_dir/mihomo" "$install_dir/mihomo_bak"
    fi

    # Распаковка архива Mihomo
    if [ -d "${mtmp_dir}/mihomo" ]; then
        rm -r "${mtmp_dir}/mihomo"
    fi

    if ! gzip -d "${mihomo_archive}"; then
        echo -e "  ${red}Ошибка${reset}: Не удалось распаковать архив Mihomo"
        if [ -f "$install_dir/mihomo_bak" ]; then
            mv "$install_dir/mihomo_bak" "$install_dir/mihomo"
            echo -e "  ${yellow}Восстановлен${reset} предыдущий бинарник Mihomo"
        fi
        rm -f "${mihomo_archive}"
        rm -rf "${mtmp_dir}/mihomo"
        return 1
    fi

    if [ ! -f "${mtmp_dir}/mihomo" ]; then
        echo -e "  ${red}Ошибка${reset}: После распаковки не найден исполняемый файл Mihomo"
        if [ -f "$install_dir/mihomo_bak" ]; then
            mv "$install_dir/mihomo_bak" "$install_dir/mihomo"
            echo -e "  ${yellow}Восстановлен${reset} предыдущий бинарник Mihomo"
        fi
        rm -rf "${mtmp_dir}/mihomo"
        return 1
    fi

    mv "${mtmp_dir}/mihomo" $install_dir/
    chmod +x $install_dir/mihomo
    rm -f "$install_dir/mihomo_bak"
    echo -e "  Mihomo ${green}успешно установлен${reset}"

    # Удаление временных файлов
    rm -rf "${mtmp_dir}/mihomo"
    return 0
}