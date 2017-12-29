<?php

$config['db_extension'] = 'mysqli';
$config['db_host']      = 'localhost';
$config['db_user']      = 'observium';
$config['db_pass']      = '$OBSERVIUM_MYSQL_PASSWORD';
$config['db_name']      = 'observium';

$config['install_dir'] = "/opt/observium";

$config['snmp']['community'][0] = "$OBSERVIUM_DEFAULT_SNMPV2C_COMMUNITY";

$config['auth_mechanism'] = "mysql";

$config['poller-wrapper']['alerter'] = TRUE;

$config['frontpage']['order'] = ['alert_table'];
