FROM centos:7

# Set default environment varibles
ENV DB_ENDPOINT=gcloud-docker-demo:us-central1:moodle-db
ENV DB_TYPE=mysqli
ENV DB_HOST=127.0.0.1
ENV DB_PORT=3306
ENV DB_NAME=moodle
ENV DB_USER=moodleuser
ENV DB_PASS=m00dLe
ENV ADMIN_PASS=m00dLe
ENV MOODLE_DATA=10.72.88.234:/moodledata
ENV INIT_DB=0
ENV MOODLE_URL=http://localhost/moodle

# Add epel repo
RUN yum install -y epel-release; yum clean all; yum -y update --nogpgcheck
RUN rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# Install php7.0 with modules
RUN yum install -y php70w php70w-curl php70w-gd php70w-intl php70w-ldap php70w-mysqlnd php70w-pspell \
php70w-xml php70w-xmlrpc php70w-zip php70w-common php70w-opcache php70w-mbstring php70w-soap

# Install python libs
RUN yum install -y libselinux-python libsemanage-python

# Install mysql client
RUN yum -y install mariadb-server mariadb

# Install apache2
RUN yum install -y httpd

# install sql proxy for db connection
#RUN yum -y install wget && \
#wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy && \
#chmod +x cloud_sql_proxy
#RUN ./cloud_sql_proxy -instances="$DB_ENDPOINT"=tcp:3306 &

# Download and untar latest Moodle
ADD https://download.moodle.org/download.php/direct/stable35/moodle-latest-35.tgz /var/www/html
RUN tar xzf /var/www/html/moodle-latest-35.tgz -C /var/www/html; echo "---> Unarchive completed"

# Install nfs-utils
RUN yum -y update && yum -y install nfs-utils

# Mount fileshare
#RUN mkdir -m 755 /var/moodledata && \
#mount 10.72.88.234:/moodledata /var/moodledata && \
#chmod go+rw /var/moodledata

# Add start script
ADD install_moodle.sh /

# Expose port 80 by default
EXPOSE 80

# Run Moodle installation script when container starts
RUN chmod 755 /install_moodle.sh
ENTRYPOINT ["/install_moodle.sh"]
