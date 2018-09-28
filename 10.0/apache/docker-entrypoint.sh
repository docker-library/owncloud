#!/bin/bash
set -e

if [ ! -e '/var/www/html/version.php' ]; then
	tar cf - --one-file-system -C /usr/src/owncloud . | tar xf -
	find /var/www/html \! -user www-data -exec chown www-data '{}' +
fi

exec "$@"
