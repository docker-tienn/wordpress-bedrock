#!/bin/bash
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}
envs=(
  DB_HOST
  DB_USER
  DB_PASSWORD
  DB_NAME
  DB_PREFIX
  WP_ENV
  WP_HOME
  WP_SITEURL
)
for e in "${envs[@]}"; do
  file_env "$e"
done

if [ -z "$DB_NAME" ]; then
  DB_NAME=wordpress
fi

if [ -z "$DB_USER" ]; then
  DB_USER=root
fi

if [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD=
fi

if [ -z "$DB_HOST" ]; then
  DB_HOST=localhost
fi

if [ -z "$DB_PREFIX" ]; then
  DB_PREFIX=wp_
fi

if [ -z "$WP_ENV" ]; then
  WP_ENV=development
fi

if [ -z "$WP_HOME" ]; then
  WP_HOME=http://localhost
fi

alias wp="wp --allow-root"
wp --allow-root package install aaemnnosttv/wp-cli-dotenv-command:^1.0
wp --allow-root dotenv init --with-salts --force

### Setting up WP Bedrock
wp --allow-root dotenv set DB_NAME $DB_NAME
wp --allow-root dotenv set DB_USER $DB_USER
wp --allow-root dotenv set DB_PASSWORD "$DB_PASSWORD" --quote-double
wp --allow-root dotenv set DB_HOST $DB_HOST
wp --allow-root dotenv set DB_PREFIX $DB_PREFIX
wp --allow-root dotenv set WP_ENV $WP_ENV
wp --allow-root dotenv set WP_HOME "$WP_HOME" --quote-double

for e in "${envs[@]}"; do
  unset "$e"
done

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
