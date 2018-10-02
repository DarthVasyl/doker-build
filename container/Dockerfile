FROM centos:7
LABEL version="3.5-beta" maintainer="Vasyl Doroshenko" 

# Set default environment varibles
ENV MOODLE_URL=http://35.239.101.65/moodle
ENV MOODLE_DATA=/var/moodledata
ENV DB_TYPE=mysqli
ENV DB_HOST=127.0.0.1
ENV DB_PORT=3306
ENV DB_NAME=moodle
ENV DB_USER=moodleuser
ENV DB_PASS=m00dLe
ENV ADMIN_PASS=m@Dm1n
ENV INIT_DB=0

# Add epel repo
RUN yum install -y epel-release; yum clean all; yum -y update --nogpgcheck
RUN rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# Install php7.0 with modules
RUN yum install -y php70w php70w-curl php70w-gd php70w-intl php70w-ldap php70w-mysqlnd php70w-pspell \
php70w-xml php70w-xmlrpc php70w-zip php70w-common php70w-opcache php70w-mbstring php70w-soap

# Install python libs
#RUN yum install -y libselinux-python libsemanage-python

# Install mysql client
# RUN yum -y install mariadb-server mariadb

# Install apache2
RUN yum install -y httpd

# Download and untar latest Moodle
ADD https://download.moodle.org/download.php/direct/stable35/moodle-latest-35.tgz /var/www/html
RUN tar -xzf /var/www/html/moodle-latest-35.tgz -C /var/www/html && \
    rm /var/www/html/moodle-latest-35.tgz && \
    echo "---> Unarchive completed"

# make directory for share files
RUN mkdir -m 755 $MOODLE_DATA
VOLUME ["$MOODLE_DATA"]

# Add start script
COPY install_moodle.sh /

# Expose port 80 by default
EXPOSE 80

# Run Moodle installation script when container starts
RUN chmod 755 /install_moodle.sh
ENTRYPOINT ["/install_moodle.sh"]
