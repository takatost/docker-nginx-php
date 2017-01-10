#!/bin/sh

if [ $SCHEDULE_ON = "yes" ]; then 
        /usr/local/bin/php /data/www/artisan schedule:run
else
        echo "no\n"
fi