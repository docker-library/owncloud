#!/bin/bash
set -e

if [ "$MYSQL_NAME" ]; then
	echo "Successfully linked to MySQL!"
	sed -r \
		-e "s/('dbtype' => )'sqlite',/\1'mysql',/g" \
		-e "s/('dbhost' => )'',/\1'mysql',/g" \
		-e "s/('dbuser' => )'',/\1'root',/g" \
		-e "s/('dbpassword' => )'',/\1'${MYSQL_ENV_MYSQL_ROOT_PASSWORD}',/g" \
		-e "s/    'demo.example.org',/    0 => 'localhost',/g" \
		-e "s/    'otherdomain.example.org',//g" \
		owncloud/config/config.sample.php > owncloud/config/config.php
	chown -R www-data /var/www
else
	echo "No linked MySQL container named 'mysql'!"
	exit 1
fi

exec "$@"
