FROM php:5.4-apache

RUN apt-get update && apt-get install -y \
	bzip2 \
	g++ \
	libcurl4-openssl-dev \
	libfreetype6-dev \
	libicu-dev \
	libjpeg62-turbo-dev \
	libmcrypt-dev \
	libpng12-dev \
	libpq-dev \
	libxml2-dev \
	&& rm -rf /var/lib/apt/lists/*

#gpg key from https://owncloud.org/owncloud.asc
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys E3036906AD9F30807351FAC32D5D5E97F6978A26

# https://doc.owncloud.org/server/8.1/admin_manual/installation/source_installation.html#prerequisites
RUN docker-php-ext-install curl gd iconv intl json mbstring mcrypt mysql pgsql simplexml xml xmlwriter zip

ENV OWNCLOUD_VERSION 7.0.4

RUN curl -fsSL -o owncloud.tar.bz2 \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2" \
	&& curl -fsSL -o owncloud.tar.bz2.asc \
		"https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2.asc" \
	&& gpg --verify owncloud.tar.bz2.asc \
	&& tar -xjf owncloud.tar.bz2 -C /var/www/html --strip-components=1 \
	&& rm owncloud.tar.bz2 owncloud.tar.bz2.asc \
	&& chown -R www-data /var/www/html
