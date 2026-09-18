<?php

/* Directory holding the phpMyAdmin configuration files. Overridable so the
 * configuration can be unit-tested outside the container (see
 * testing/test_config.php); defaults to the in-container location. */
$configDir = getenv('PMA_CONFIG_DIR');
if ($configDir === false || $configDir === '') {
    $configDir = '/etc/phpmyadmin';
}

require($configDir . '/config.secret.inc.php');

/* Ensure we got the environment */
$vars = array(
    'PMA_ARBITRARY',
    'PMA_HOST',
    'PMA_HOSTS',
    'PMA_VERBOSE',
    'PMA_VERBOSES',
    'PMA_PORT',
    'PMA_PORTS',
    'PMA_USER',
    'PMA_PASSWORD',
    'PMA_ABSOLUTE_URI'
);
foreach ($vars as $var) {
    $env = getenv($var);
    if (!isset($_ENV[$var]) && $env !== false) {
        $_ENV[$var] = $env;
    }
}

/* Arbitrary server connection */
if (isset($_ENV['PMA_ARBITRARY']) && $_ENV['PMA_ARBITRARY'] === '1') {
    $cfg['AllowArbitraryServer'] = true;
}

/* Play nice behind reverse proxys */
if (isset($_ENV['PMA_ABSOLUTE_URI'])) {
    $cfg['PmaAbsoluteUri'] = trim($_ENV['PMA_ABSOLUTE_URI']);
}

/* Figure out hosts */

/* Fallback to default linked */
$hosts = array('db');

/* Set by environment */
if (!empty($_ENV['PMA_HOST'])) {
    $hosts = array($_ENV['PMA_HOST']);
    $verbose = isset($_ENV['PMA_VERBOSE']) ? array($_ENV['PMA_VERBOSE']) : array();
    $ports = isset($_ENV['PMA_PORT']) ? array($_ENV['PMA_PORT']) : array();
} elseif (!empty($_ENV['PMA_HOSTS'])) {
    $hosts = explode(',', $_ENV['PMA_HOSTS']);
    $verbose = isset($_ENV['PMA_VERBOSES']) ? explode(',', $_ENV['PMA_VERBOSES']) : array();
    $ports = isset($_ENV['PMA_PORTS']) ? explode(',', $_ENV['PMA_PORTS']) : array();
}

/* Server settings */
for ($i = 1; isset($hosts[$i - 1]); $i++) {
    $cfg['Servers'][$i]['host'] = $hosts[$i - 1];
    if (isset($verbose[$i - 1])) {
        $cfg['Servers'][$i]['verbose'] = $verbose[$i - 1];
    }
    if (isset($ports[$i - 1])) {
        $cfg['Servers'][$i]['port'] = $ports[$i - 1];
    }
    if (isset($_ENV['PMA_USER'])) {
        $cfg['Servers'][$i]['auth_type'] = 'config';
        $cfg['Servers'][$i]['user'] = $_ENV['PMA_USER'];
        $cfg['Servers'][$i]['password'] = isset($_ENV['PMA_PASSWORD']) ? $_ENV['PMA_PASSWORD'] : '';
    } else {
        $cfg['Servers'][$i]['auth_type'] = 'cookie';
    }
    $cfg['Servers'][$i]['compress'] = false;
    $cfg['Servers'][$i]['AllowNoPassword'] = true;
}
/*
 * Revert back to last configured server to make
 * it easier in config.user.inc.php
 */
$i--;

/* Uploads setup */
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';

/* Include User Defined Settings Hook */
if (file_exists($configDir . '/config.user.inc.php')) {
    include($configDir . '/config.user.inc.php');
}
