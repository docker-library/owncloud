#!/bin/bash
set -e

if [ "$(ls -A /var/www/html)" ]; then
	tar cf - --one-file-system -C /usr/src/owncloud . | tar xf -
	chown -R www-data /var/www/html
fi

exec "$@"
