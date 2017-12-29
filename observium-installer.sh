#!/bin/bash

# Exit if there is an error
set -e


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If script is executed as an unprivileged user
# Execute it as superuser, preserving environment variables
if [ $EUID != 0 ]; then
    sudo -E "$0" "$@"
    exit $?
fi

# If there is an .env file use it
# to set the variables
if [ -f $SCRIPT_DIR/.env ]; then
    source $SCRIPT_DIR/.env
fi

# Check all required variables are set
: "${OBSERVIUM_MYSQL_ROOT_PASSWORD:?must be set}"
: "${OBSERVIUM_MYSQL_PASSWORD:?must be set}"
: "${OBSERVIUM_SVN_USERNAME:?must be set}"
: "${OBSERVIUM_SVN_PASSWORD:?must be set}"
: "${OBSERVIUM_WEB_USERNAME:?must be set}"
: "${OBSERVIUM_WEB_PASSWORD:?must be set}"

# Set additional environment variables
export OBSERVIUM_FQDN=$(hostname -f)
export OBSERVIUM_DEFAULT_SNMPV2C_COMMUNITY=${OBSERVIUM_DEFAULT_SNMPV2C_COMMUNITY:-public}

# Prevent apt prompting for input
export DEBIAN_FRONTEND="noninteractive"

# Set root password from environment variable
/usr/bin/debconf-set-selections <<< "mysql-server mysql-server/root_password password $OBSERVIUM_MYSQL_ROOT_PASSWORD"
/usr/bin/debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $OBSERVIUM_MYSQL_ROOT_PASSWORD"

# Install required packages
/usr/bin/apt update -y
/usr/bin/apt install -y apache2 \
                        fping \
                        graphviz \
                        imagemagick \
                        ipmitool \
                        libapache2-mod-php7.0 \
                        mtr-tiny \
                        mysql-client \
                        mysql-server \
                        nmap \
                        php-pear \
                        php7.0-cli \
                        php7.0-gd \
                        php7.0-json \
                        php7.0-mcrypt \
                        php7.0-mysql \
                        php7.0-mysqli \
                        python-mysqldb \
                        rrdtool \
                        snmp \
                        subversion \
                        whois

# Set up database, user and privileges
/usr/bin/mysql -u root -p$OBSERVIUM_MYSQL_ROOT_PASSWORD --execute \
	"CREATE DATABASE observium DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci"

/usr/bin/mysql -u root -p$OBSERVIUM_MYSQL_ROOT_PASSWORD --execute \
	"GRANT ALL PRIVILEGES ON observium.* TO 'observium'@'localhost' IDENTIFIED BY '$OBSERVIUM_MYSQL_PASSWORD'"

# Create directories
mkdir -p /opt/observium/logs/
mkdir -p /opt/observium/rrd/

# Enable PHP and Apache modules
/usr/sbin/phpenmod mcrypt
/usr/sbin/a2enmod rewrite

# Install Apache configuration
/usr/bin/envsubst '$OBSERVIUM_FQDN' < $SCRIPT_DIR/configs/apache2/observium.conf > /etc/apache2/sites-available/observium.conf

# Disable default Apache site and enable Observium configuration
/usr/sbin/a2dissite 000-default
/usr/sbin/a2ensite observium

# Restart Apache
/usr/sbin/apache2ctl restart

# Download Observium from SVN
/usr/bin/svn checkout --username "$OBSERVIUM_SVN_USERNAME" --password "$OBSERVIUM_SVN_PASSWORD" --non-interactive \
             http://svn.observium.org/svn/observium/branches/stable /opt/observium/

# Install Observium configuration
/usr/bin/envsubst '$OBSERVIUM_MYSQL_PASSWORD $OBSERVIUM_DEFAULT_SNMPV2C_COMMUNITY' < $SCRIPT_DIR/configs/observium/config.php > /opt/observium/config.php

# Run Observium upgrade script to create database structure
cd /opt/observium && /opt/observium/discovery.php -u

# Add web console admin user
cd /opt/observium && /opt/observium/adduser.php $OBSERVIUM_WEB_USERNAME "$OBSERVIUM_WEB_PASSWORD" 10

# Change group and owner to www-data for all files and directories
chown -R www-data:www-data /opt/observium

# Add current user to www-data group to allow editing of files
/usr/sbin/adduser $(/usr/bin/logname) www-data

# Install Cron jobs
cp $SCRIPT_DIR/configs/cron.d/observium /etc/cron.d/observium

# Download observium-alerts.sh
/usr/bin/git clone https://github.com/zeropingheroes/observium-alerts.git /usr/local/bin/observium-alerts

# Import alerts
/usr/local/bin/observium-alerts/observium-alerts.sh import /usr/local/bin/observium-alerts/sample_alerts.sql

# Download observium-nmap-autodiscover.sh
/usr/bin/git clone https://github.com/zeropingheroes/observium-nmap-autodiscover.git /usr/local/bin/observium-nmap-autodiscover

# Scan the local network and add any devices running SNMP
/usr/local/bin/observium-nmap-autodiscover/observium-nmap-autodiscover.sh
