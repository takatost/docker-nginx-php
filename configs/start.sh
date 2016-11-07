#!/bin/sh

Nginx_Install_Dir=/usr/local/nginx
Php_Install_Dir=/usr/local/php
DATA_DIR=/data/www

set -e

export PATH=$PATH:$Nginx_Install_Dir/sbin
export PATH=$PATH:$Nginx_Install_Dir/bin

/usr/local/bin/supervisord -n -c /etc/supervisord.conf