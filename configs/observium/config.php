<?php

$config['db_extension'] = 'mysqli';
$config['db_host']      = 'localhost';
$config['db_user']      = 'observium';
$config['db_pass']      = '$OBSERVIUM_MYSQL_PASSWORD';
$config['db_name']      = 'observium';

$config['install_dir'] = "/opt/observium";

$config['snmp']['community'] = array("public");

$config['auth_mechanism'] = "mysql";

$config['poller-wrapper']['alerter'] = TRUE;
