#!/bin/sh

Nginx_Install_Dir=/usr/local/nginx
Php_Install_Dir=/usr/local/php
DATA_DIR=/data/www

set -e

export PATH=$PATH:$Nginx_Install_Dir/sbin
export PATH=$PATH:$Nginx_Install_Dir/bin

rm -rf /etc/default/locale
env >> /etc/default/locale
/etc/init.d/cron start

/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf
