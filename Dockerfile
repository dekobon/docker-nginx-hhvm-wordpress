# dekobon/docker-nginx-hhvm-wordpress:latest
FROM phusion/baseimage:0.9.17
MAINTAINER Elijah Zupancic <elijah@zupancic.name>

# We group all of the apt commands together here so that our image size doesn't bloat.
# Below we:
# 1. Update and upgrade existing packages
# 2. Install needed base packages
# 3. Install HHVM
# 4. Clean up
RUN add-apt-repository ppa:rtcamp/nginx && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install nginx-custom php5-mysql php-apc curl unzip postfix php5-curl php5-gd php5-intl \
                       php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps \
                       php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl mysql-client && \
    curl http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add - && \
    echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list && \
    apt-get update && \
    apt-get install -y hhvm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Wordpress CLI
ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

COPY etc/syslog-ng/conf.d/sources.conf /etc/syslog-ng/conf.d/sources.conf

# nginx config
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf

# nginx site conf
COPY etc/nginx/sites-available/default /etc/nginx/sites-available/default

RUN mkdir /etc/service/nginx
COPY etc/service/nginx/run /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

# HHVM setup
RUN mkdir /etc/service/hhvm
COPY etc/service/hhvm/run /etc/service/hhvm/run
RUN chmod +x /etc/service/hhvm/run

RUN sudo /usr/share/hhvm/install_fastcgi.sh

RUN chown -R www-data:www-data /var/www

# Send all PHP errors to syslog
RUN echo 'error_log = syslog' >> /etc/php5/cli/php.ini
RUN echo 'error_log = syslog' >> /etc/hhvm/php.ini

RUN rm -rf /tmp/* /var/tmp/*

# Define mountable directories.
VOLUME ["/usr/share/nginx/www","/var/log/nginx"]

# private expose
EXPOSE 80
EXPOSE 443

CMD ["/sbin/my_init"]
