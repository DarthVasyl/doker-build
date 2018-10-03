#!/bin/bash

# Install Moodle
/usr/bin/php /var/www/html/moodle/admin/cli/install.php \
    --wwwroot=$MOODLE_URL \
    --dataroot=$MOODLE_DATA \
    --dbtype=$DB_TYPE \
    --dbhost=$DB_HOST \
    --dbport=$DB_PORT \
    --dbname=$DB_NAME \
    --dbuser=$DB_USER \
    --dbpass=$DB_PASS \
    --fullname="Docker Moodle" \
    --adminpass=$ADMIN_PASS  \
    --shortname="Moodle" \
    --non-interactive \
    --agree-license \
    $(if [ $INIT_DB -eq 0 ]; then echo "--skip-database"; fi)

# add Redis configuration
sed -i '/^\s*require_once/i\\$CFG->session_redis_host = '"'${REDIS_SERVER}';" /var/www/html/moodle/config.php
sed -i '/^\s*require_once/i\\$CFG->session_handler_class = '"'"'\\core\\session\\redis'"'"'\;' /var/www/html/moodle/config.php
sed -i '/^\s*require_once/i\\$CFG->session_redis_acquire_lock_timeout = 120;' /var/www/html/moodle/config.php
sed -i '/^\s*require_once/i\\$CFG->session_redis_lock_expire = 7200;' /var/www/html/moodle/config.php

#Enable Redis in PHP
echo "session.save_handler = redis" >> /etc/php.d/redis.ini
echo "session.save_path = \"tcp://${REDIS_SERVER}:6379\"" >> /etc/php.d/redis.ini

# Make apache owner of moodle files
chown -R apache:apache /var/moodledata
chown -R apache:apache /var/www/html

# Run apache server
/usr/sbin/httpd -D FOREGROUND
