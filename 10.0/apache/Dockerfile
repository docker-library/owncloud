# https://owncloud.com/minimum-product-requirements/ ("5.6 recommended")
# https://doc.owncloud.org/server/10.0/admin_manual/installation/system_requirements.html ("PHP (5.6+ or 7.0+)")
# https://doc.owncloud.org/server/9.0/admin_manual/installation/system_requirements.html ("PHP 7.0")
FROM php:7.0-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		gnupg dirmngr \
		libcurl4-openssl-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg-dev \
		libldap2-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libpng-dev \
		libpq-dev \
		libxml2-dev \
		unzip \
	&& rm -rf /var/lib/apt/lists/*

# https://doc.owncloud.org/server/8.1/admin_manual/installation/source_installation.html#prerequisites
RUN set -ex; \
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
	docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
	docker-php-ext-install -j "$(nproc)" \
		exif \
		gd \
		intl \
		ldap \
		mbstring \
		mcrypt \
		opcache \
		pcntl \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN a2enmod rewrite

# PECL extensions
RUN set -ex; \
	pecl install APCu-5.1.11; \
	pecl install memcached-3.0.4; \
	pecl install redis-3.1.6; \
	docker-php-ext-enable \
		apcu \
		memcached \
		redis

ENV OWNCLOUD_VERSION 10.0.9
ENV OWNCLOUD_SHA256 767faedf7b236b469e71ad73a70c6250fc33fd493708d95cf31b0b58b4710973
VOLUME /var/www/html

RUN set -eux; \
	curl -fL -o owncloud.tar.bz2 "https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2"; \
	curl -fL -o owncloud.tar.bz2.asc "https://download.owncloud.org/community/owncloud-${OWNCLOUD_VERSION}.tar.bz2.asc"; \
	echo "$OWNCLOUD_SHA256 *owncloud.tar.bz2" | sha256sum -c -; \
	export GNUPGHOME="$(mktemp -d)"; \
# gpg key from https://owncloud.org/owncloud.asc
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys E3036906AD9F30807351FAC32D5D5E97F6978A26; \
	gpg --batch --verify owncloud.tar.bz2.asc owncloud.tar.bz2; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -r "$GNUPGHOME" owncloud.tar.bz2.asc; \
	tar -xjf owncloud.tar.bz2 -C /usr/src/; \
	rm owncloud.tar.bz2

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
