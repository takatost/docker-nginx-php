FROM debian:jessie

MAINTAINER takatost <takatost@gmail.com>

ENV NGINX_VERSION 1.11.5
ENV PHP_VERSION 7.0.12

RUN set -x

RUN apt-get update
RUN apt-get install -y git \
    curl \
    cron \
    gcc \
    build-essential  \
    autoconf \
    automake \
    libtool \
    make \
    cmake \
    expect \
    dstat

#Install PHP library
RUN apt-get install -y libbz2-dev \
    libcurl4-openssl-dev\
    libssl-dev \
    libgd2-dev \
    libpcre3-dev \
    libfreetype6-dev \
    libxml2-dev \
    libpng++-dev \
    libmcrypt-dev \
    python-setuptools

#Add user
RUN mkdir -p /data/www && \
    useradd -r -s /sbin/nologin -d /data/www -m -k no www

#Download nginx & php
RUN mkdir -p /home/nginx-php && cd $_ && \
    curl -Lk http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php && \
    curl -Lk http://php.net/distributions/php-$PHP_VERSION.tar.gz | gunzip | tar x -C /home/nginx-php

#Make install nginx
RUN cd /home/nginx-php/nginx-$NGINX_VERSION && \
    ./configure --prefix=/usr/local/nginx \
    --user=www --group=www \
    --error-log-path=/var/log/nginx_error.log \
    --http-log-path=/var/log/nginx_access.log \
    --pid-path=/var/run/nginx.pid \
    --with-pcre \
    --with-http_ssl_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --with-http_gzip_static_module && \
    make && make install && \
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

#Make install php
RUN cd /home/nginx-php/php-$PHP_VERSION && \
    ./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --with-config-file-scan-dir=/usr/local/php/etc/php.d \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-mcrypt=/usr/include \
    --with-pdo-mysql \
    --with-openssl \
    --with-gd \
    --with-iconv \
    --with-zlib \
    --with-curl \
    --with-png-dir \
    --with-jpeg-dir \
    --with-freetype-dir \
    --with-xmlrpc \
    --with-mhash \
    --enable-fpm \
    --enable-xml \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-ftp \
    --enable-gd-native-ttf \
    --enable-pcntl \
    --enable-sockets \
    --enable-zip \
    --enable-soap \
    --enable-session \
    --enable-opcache \
    --enable-bcmath \
    --enable-exif \
    --enable-fileinfo \
    --disable-rpath \
    --enable-ipv6 \
    --disable-debug \
    --without-pear && \
    make && make install && \

#Install php-fpm
    cd /home/nginx-php/php-$PHP_VERSION && \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf && \
    ln -s /usr/local/php/bin/php /usr/local/bin/php

#Install supervisor
RUN easy_install supervisor && \
    mkdir -p /var/{log/supervisor,run/{sshd,supervisord}}

#Install php-kafka
COPY configs/pear_install.sh /tmp/
RUN cd /tmp && \
    chmod 0744 pear_install.sh && \
    /usr/bin/expect pear_install.sh && \
    mkdir /tmp/librdkafka && \
    cd /tmp/librdkafka && \
    git clone https://github.com/edenhill/librdkafka.git . && \
    ./configure && \
    make && \
    make install && \
    /usr/local/php/bin/pecl install channel://pecl.php.net/rdkafka-beta && \
    rm -rf /tmp/librdkafka

#Clean OS
RUN apt-get remove -y gcc \
    autoconf \
    automake \
    libtool \
    make \
    expect \
    cmake && \
    apt-get clean all && \
    rm -rf /tmp/* /etc/my.cnf{,.d} && \
    find /var/log -type f -delete && \
    rm -rf /home/nginx-php && \

#Change Mod from webdir
    chown -R www:www /data/www

#Add supervisord conf
RUN mkdir /etc/supervisor/conf.d

COPY configs/supervisord.conf /etc/supervisor/
COPY configs/conf.d/ /etc/supervisor/conf.d/

#Update nginx config
COPY configs/nginx.conf /usr/local/nginx/conf/

#Update php config
COPY configs/php.ini /usr/local/php/etc/

#Update php pool config
COPY configs/www.conf /usr/local/php/etc/php-fpm.d/

#Add cron config
COPY configs/www /var/spool/cron/crontabs/
RUN chown -R www:crontab /var/spool/cron/crontabs/www && \
 	chmod 600 /var/spool/cron/crontabs/www && \
    touch /var/log/cron.log

#Start
COPY configs/start.sh /
RUN chmod +x /start.sh

#Set port
EXPOSE 80 443

#Start it
ENTRYPOINT ["/start.sh"]
