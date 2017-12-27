#!/bin/bash

# Exit if there is an error
set -e

# If script is executed as an unprivileged user
# Execute it as superuser, preserving environment variables
if [ $EUID != 0 ]; then
    sudo -E "$0" "$@"
    exit $?
fi

# Check all required variables are set
: "${OBSERVIUM_MYSQL_ROOT_PASSWORD:?must be set}"

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

