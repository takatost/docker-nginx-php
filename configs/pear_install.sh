#!/usr/bin/expect
spawn php /tmp/go-pear.phar

expect "1-11, 'all' or Enter to continue:"
send "\r"
expect eof

spawn rm /tmp/go-pear.phar