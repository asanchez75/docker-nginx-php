FROM million12/nginx:latest
MAINTAINER Marcin Ryzycki <marcin@m12.io>

ADD container-files/config/install* /config/

RUN \
  rpm --rebuilddb && yum update -y && \
  `# Install yum-utils (provides yum-config-manager) + some basic web-related tools...` \
  yum install -y yum-utils wget patch mysql tar bzip2 unzip openssh-clients rsync && \

  `# Install PHP 5.6` \
  rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
  yum-config-manager -q --enable remi && \
  yum-config-manager -q --enable remi-php56 && \
  yum install -y php-fpm php-bcmath php-cli php-gd php-intl php-mbstring \
                  php-pecl-imagick php-mcrypt php-mysql php-opcache php-pdo php-bcmath php-devel mlocate nano git && \
  yum install -y --disablerepo=epel php-pecl-redis php-pecl-yaml && \

  `# Install libs required to build some gem/npm packages (e.g. PhantomJS requires zlib-devel, libpng-devel)` \
  yum install -y ImageMagick GraphicsMagick gcc gcc-c++ libffi-devel libpng-devel zlib-devel && \

  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  chown www /usr/local/bin/composer

ADD container-files /

RUN cd /tmp && wget https://github.com/alexeyrybak/blitz/archive/0.9.1.tar.gz && \
    tar xvzf 0.9.1.tar.gz && cd /tmp/blitz-0.9.1 && \
    phpize && ./configure && make && make install

RUN sed -i '$ a extension=/usr/lib64/php/modules/blitz.so' /etc/php.ini
RUN sed -i '$ a env[DATABASE_HOST] = $DATABASE_HOST' /etc/php-fpm.d/www.conf
RUN sed -i '$ a env[DATABASE_NAME] = $DATABASE_NAME' /etc/php-fpm.d/www.conf
RUN sed -i '$ a env[DATABASE_USER] = $DATABASE_USER' /etc/php-fpm.d/www.conf
RUN sed -i '$ a env[DATABASE_PASSWORD] = $DATABASE_PASSWORD' /etc/php-fpm.d/www.conf

ENV STATUS_PAGE_ALLOWED_IP=127.0.0.1
