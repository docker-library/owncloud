FROM php:5.4-apache

#gpg key from https://owncloud.org/owncloud.asc

ENV OWNCLOUD_VERSION 8.0.2

RUN apt-get update && apt-get install -y \
	bzip2 \
	g++ \
	libfreetype6-dev \
	libicu-dev \
	libjpeg62-turbo-dev \
	libmcrypt-dev \
	libpng12-dev \
	libxml2-dev

RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys E3036906AD9F30807351FAC32D5D5E97F6978A26
RUN curl -s -o owncloud.tar.bz2 \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2" \
	&& curl -s -o owncloud.tar.bz2.asc \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2.asc" \
	&& gpg --verify owncloud.tar.bz2.asc \
	&& tar -xjf owncloud.tar.bz2 -C /var/www/html \
	&& rm owncloud.tar.bz2 owncloud.tar.bz2.asc \
	&& chown -R www-data /var/www/html

RUN docker-php-ext-install gd iconv mcrypt json intl xmlwriter zip xml simplexml mbstring pdo pdo_mysql
COPY docker-entrypoint.sh /docker-entrypoint.sh

#ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2", "-D", "FOREGROUND"]
