#!/bin/sh

green="\033[92m"
red="\033[91m"
yellow="\033[93m"
light_blue="\033[96m"
reset="\033[0m"

url_stable="https://github.com/jameszeroX/XKeen/releases/latest/download/xkeen.tar.gz"
url_beta="https://raw.githubusercontent.com/jameszeroX/XKeen/main/test/xkeen.tar.gz"
archive_name="xkeen.tar.gz"
sha256_name="xkeen.tar.gz.sha256"

clear
echo
printf "  Какую версию ${yellow}XKeen${reset} вы хотите установить?\n\n"
printf "  1) Стабильную версию (${light_blue}Stable${reset})\n"
printf "  2) Новую Бета-версию (${light_blue}Beta${reset})\n\n"
printf "  Выберите 1 или 2 [по умолчанию 1]: "
read -r version_choice

case "$version_choice" in
    2)
        url="$url_beta"
        echo
        printf "  Выбрана ${light_blue}Бета-версия${reset}\n"
        ;;
    *)
        url="$url_stable"
        echo
        printf "  Выбрана ${light_blue}Стабильная версия${reset}\n"
        ;;
esac
echo

download_xkeen_release() {
    if curl -fLo "$archive_name" --connect-timeout 10 -m 180 "$url"; then
        return 0
    fi

    if curl -fLo "$archive_name" --connect-timeout 10 -m 180 "https://gh-proxy.com/$url"; then
        return 0
    fi

    if curl -fLo "$archive_name" --connect-timeout 10 -m 180 "https://ghfast.top/$url"; then
        return 0
    fi

    printf "  ${red}Ошибка${reset}: не удалось загрузить ${yellow}xkeen.tar.gz${reset}\n"
    return 1
}

# Загружает sha256-чексумму с того же зеркала, что и архив.
# Возвращает 0 если файл успешно загружен и непуст, 1 если ни одно зеркало не отдало.
download_sha256() {
    sha_url="${url}.sha256"

    if curl -fLo "$sha256_name" --connect-timeout 10 -m 60 "$sha_url" 2>/dev/null; then
        [ -s "$sha256_name" ] && return 0
    fi

    if curl -fLo "$sha256_name" --connect-timeout 10 -m 60 "https://gh-proxy.com/$sha_url" 2>/dev/null; then
        [ -s "$sha256_name" ] && return 0
    fi

    if curl -fLo "$sha256_name" --connect-timeout 10 -m 60 "https://ghfast.top/$sha_url" 2>/dev/null; then
        [ -s "$sha256_name" ] && return 0
    fi

    rm -f "$sha256_name"
    return 1
}

# Проверяет sha256 архива.
# Поведение:
#   - .sha256 не найден ни на одном зеркале → soft-warn (бэк-совместимость со старыми
#     релизами, опубликованными до введения чексумм). Установка продолжается.
#   - .sha256 найден, но не совпадает → hard-fail. Возможен MITM на gh-зеркале или
#     повреждение при загрузке.
verify_archive_sha256() {
    if ! command -v sha256sum >/dev/null 2>&1; then
        printf "  ${yellow}Предупреждение${reset}: утилита sha256sum недоступна — пропускаем проверку целостности\n"
        return 0
    fi

    if ! download_sha256; then
        printf "  ${yellow}Предупреждение${reset}: контрольная сумма ${yellow}${sha256_name}${reset} недоступна\n"
        printf "  Установка продолжается без проверки целостности (старый релиз?)\n"
        return 0
    fi

    expected_sha=$(awk '{print $1}' "$sha256_name" 2>/dev/null | tr -d '[:space:]')
    rm -f "$sha256_name"

    if [ -z "$expected_sha" ]; then
        printf "  ${yellow}Предупреждение${reset}: файл ${yellow}${sha256_name}${reset} пуст или некорректен — пропускаем проверку\n"
        return 0
    fi

    actual_sha=$(sha256sum "$archive_name" | awk '{print $1}')

    if [ "$expected_sha" = "$actual_sha" ]; then
        printf "  Целостность ${yellow}xkeen.tar.gz${reset} ${green}подтверждена${reset}\n"
        return 0
    fi

    printf "  ${red}Ошибка${reset}: контрольная сумма ${yellow}xkeen.tar.gz${reset} не совпадает\n"
    printf "    ожидалось: ${expected_sha}\n"
    printf "    получено:  ${actual_sha}\n"
    printf "  Возможен MITM на зеркале или повреждение при загрузке. Установка прервана\n"
    rm -f "$archive_name"
    return 1
}

if ! download_xkeen_release; then
    exit 1
fi

if ! verify_archive_sha256; then
    exit 1
fi

if ! tar -xzf "$archive_name" -C /opt/sbin; then
    rm -f "$archive_name"
    printf "  ${red}Ошибка${reset}: не удалось распаковать ${yellow}xkeen.tar.gz${reset}\n"
    exit 1
fi

rm -f "$archive_name"

if [ ! -x /opt/sbin/xkeen ]; then
    printf "  ${red}Ошибка${reset}: после распаковки не найден исполняемый файл ${yellow}/opt/sbin/xkeen${reset}\n"
    exit 1
fi

exec /opt/sbin/xkeen -i