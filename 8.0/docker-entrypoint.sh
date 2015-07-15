#!/bin/bash
set -e

if [ "$(ls -A /var/www/html)" ]; then
	cp -R /usr/src/owncloud/* /var/www/html
	chown -R www-data /var/www/html
fi

exec "$@"
