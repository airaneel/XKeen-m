# Импорт модулей CLI-диспетчера.
# Каждый файл содержит набор cmd_<command>() функций, которые вызываются
# из главного scripts/xkeen на основе разбора $1.
# Конвенция: ≤200 строк на файл, группировка по логической теме.

. "$xdispatch_dir/01_cmd_install.sh"
. "$xdispatch_dir/01a_cmd_install_phases.sh"
. "$xdispatch_dir/02_cmd_install_offline.sh"
. "$xdispatch_dir/03_cmd_remove_full.sh"
. "$xdispatch_dir/04_cmd_update_xkeen.sh"
. "$xdispatch_dir/05_cmd_update_xray.sh"
. "$xdispatch_dir/06_cmd_update_mihomo.sh"
. "$xdispatch_dir/07_cmd_update_geo.sh"
. "$xdispatch_dir/08_cmd_reinstall.sh"
. "$xdispatch_dir/09_cmd_remove_partial.sh"
. "$xdispatch_dir/10_cmd_geo.sh"
. "$xdispatch_dir/11_cmd_cron_init.sh"
. "$xdispatch_dir/12_cmd_backups.sh"
. "$xdispatch_dir/13_cmd_lifecycle.sh"
. "$xdispatch_dir/14_cmd_ports.sh"
. "$xdispatch_dir/15_cmd_toggles.sh"
. "$xdispatch_dir/16_cmd_misc_info.sh"
