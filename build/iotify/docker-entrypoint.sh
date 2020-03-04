#!/bin/bash
set -e

if [ ! -f /etc/php.d/timezone.ini ]; then
  echo "date.timezone = $TIMEZONE" > /etc/php.d/timezone.ini
fi


chown apache:apache -R /var/www/html

exec "$@"
