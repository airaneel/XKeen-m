# Функция для установки Xray
install_xray() {
    echo -e "  ${yellow}Выполняется установка${reset} Xray. Пожалуйста, подождите..."

    # Определение переменных
    xray_archive="${xtmp_dir}/xray.zip"

    # Проверка наличия архива Xray
    if [ ! -f "${xray_archive}" ]; then
        echo -e "  ${red}Ошибка${reset}: Архив Xray не найден в '${xtmp_dir}'"
        return 1
    fi

    if [ -f "$install_dir/xray" ]; then
        mv "$install_dir/xray" "$install_dir/xray_bak"
    fi

    # Распаковка архива Xray
    if [ -d "${xtmp_dir}/xray" ]; then
        rm -r "${xtmp_dir}/xray"
    fi

    if ! unzip -q "${xray_archive}" -d "${xtmp_dir}/xray"; then
        echo -e "  ${red}Ошибка${reset}: Не удалось распаковать архив Xray"
        if [ -f "$install_dir/xray_bak" ]; then
            mv "$install_dir/xray_bak" "$install_dir/xray"
            echo -e "  ${yellow}Восстановлен${reset} предыдущий бинарник Xray"
        fi
        rm -f "${xray_archive}"
        rm -rf "${xtmp_dir}/xray"
        return 1
    fi

    if [ ! -f "${xtmp_dir}/xray/xray" ]; then
        echo -e "  ${red}Ошибка${reset}: В архиве Xray отсутствует исполняемый файл"
        if [ -f "$install_dir/xray_bak" ]; then
            mv "$install_dir/xray_bak" "$install_dir/xray"
            echo -e "  ${yellow}Восстановлен${reset} предыдущий бинарник Xray"
        fi
        rm -f "${xray_archive}"
        rm -rf "${xtmp_dir}/xray"
        return 1
    fi

    mv "${xtmp_dir}/xray/xray" $install_dir/
    chmod +x $install_dir/xray
    rm -f "$install_dir/xray_bak"
    echo -e "  Xray ${green}успешно установлен${reset}"

    # Удаление архива Xray
    rm "${xray_archive}"

    # Удаление временных файлов
    rm -rf "${xtmp_dir}/xray"

    # Фикс для новых ядер xray: бэкапим конфиги со старым полем "transport"
    # Старый rm -f мог удалять любой файл, упомянувший слово transport (даже в комментарии).
    # Теперь матчим только литеральное "transport" (с кавычками — JSON-ключ) и переименовываем,
    # а не удаляем. Пользователь сможет восстановить вручную.
    if [ -d "$install_conf_dir" ]; then
        backup_suffix=".bak.transport-removed-$(date +%Y%m%d-%H%M%S)"
        moved_any="false"
        for file in "$install_conf_dir"/*.json; do
            [ -f "$file" ] || continue
            if grep -F -q '"transport"' "$file" 2>/dev/null; then
                mv "$file" "${file}${backup_suffix}"
                moved_any="true"
                echo -e "  ${yellow}Конфиг${reset} $(basename "$file") содержит устаревшее поле \"transport\""
                echo -e "    Перемещён в ${yellow}$(basename "$file")${backup_suffix}${reset}"
            fi
        done
        if [ "$moved_any" = "true" ]; then
            echo -e "  ${yellow}Внимание${reset}: проверьте сохранённые .bak-файлы и обновите конфигурацию вручную"
        fi
    fi

    return 0
}