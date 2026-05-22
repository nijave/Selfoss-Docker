#!/bin/sh

set -e

cat > /usr/local/etc/php/conf.d/php-session.ini <<EOF
[Session]
session.cookie_lifetime = ${PHP_COOKIE_LIFETIME:-2592000}
session.gc_maxlifetime = ${PHP_GC_MAXLIFETIME:-2592000}
EOF

exec apache2-foreground "$@"
