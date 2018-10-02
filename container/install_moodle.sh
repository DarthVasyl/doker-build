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

# Make apache owner of moodle files
chown -R apache:apache /var/moodledata
chown -R apache:apache /var/www/html

# set up crone
echo "* * * * *    /usr/bin/php /var/www/html/moodle/admin/cli/cron.php >/dev/null" >> /var/spool/cron/root

# Run apache server
/usr/sbin/httpd -D FOREGROUND
