<?php
/**
 * Standalone unit tests for etc/phpmyadmin/config.inc.php.
 *
 * The tests run config.inc.php against a sandboxed configuration directory so
 * they never touch /etc/phpmyadmin and require no live database or network.
 *
 * Usage: php testing/test_config.php
 * Requires only a PHP CLI binary; no external dependencies.
 */

$tests = 0;
$failures = 0;

function check($condition, $message)
{
    global $tests, $failures;
    $tests++;
    if ($condition) {
        echo "ok - $message\n";
    } else {
        $failures++;
        echo "not ok - $message\n";
    }
}

function check_eq($expected, $actual, $message)
{
    check(
        $expected === $actual,
        $message . ' (expected ' . var_export($expected, true) . ', got ' . var_export($actual, true) . ')'
    );
}

/* Environment variables consumed by config.inc.php. */
$envVars = array(
    'PMA_ARBITRARY',
    'PMA_HOST',
    'PMA_HOSTS',
    'PMA_VERBOSE',
    'PMA_VERBOSES',
    'PMA_PORT',
    'PMA_PORTS',
    'PMA_USER',
    'PMA_PASSWORD',
    'PMA_ABSOLUTE_URI',
);

/**
 * Load config.inc.php with a clean environment plus the given overrides.
 *
 * @param array $overrides Map of environment variable name to value.
 * @return array The $cfg array produced by config.inc.php.
 */
function load_config(array $overrides = array())
{
    global $envVars;

    foreach ($envVars as $var) {
        putenv($var);
        unset($_ENV[$var]);
    }
    foreach ($overrides as $var => $value) {
        putenv($var . '=' . $value);
    }

    $cfg = array();
    include dirname(__DIR__) . '/etc/phpmyadmin/config.inc.php';
    return $cfg;
}

/* Build a sandboxed configuration directory. */
$configDir = sys_get_temp_dir() . '/pma-config-test-' . getmypid();
if (!is_dir($configDir)) {
    mkdir($configDir, 0700, true);
}
file_put_contents(
    $configDir . '/config.secret.inc.php',
    "<?php\n\$cfg['blowfish_secret'] = 'test-secret';\n"
);
file_put_contents(
    $configDir . '/config.user.inc.php',
    "<?php\n\$cfg['user_config_included'] = true;\n"
);
putenv('PMA_CONFIG_DIR=' . $configDir);

/* 1. No environment: fall back to the linked 'db' host with cookie auth. */
$cfg = load_config();
check_eq('db', $cfg['Servers'][1]['host'], 'default host is db');
check_eq('cookie', $cfg['Servers'][1]['auth_type'], 'default auth type is cookie');
check_eq(true, $cfg['Servers'][1]['AllowNoPassword'], 'AllowNoPassword defaults to true');
check(!isset($cfg['Servers'][2]), 'no environment yields exactly one server');
check_eq(true, $cfg['user_config_included'], 'config.user.inc.php is included');

/* 2. Single host via PMA_HOST / PMA_PORT / PMA_VERBOSE. */
$cfg = load_config(array(
    'PMA_HOST' => 'dbhost',
    'PMA_PORT' => '3307',
    'PMA_VERBOSE' => 'MyDB',
));
check_eq('dbhost', $cfg['Servers'][1]['host'], 'PMA_HOST sets the host');
check_eq('3307', $cfg['Servers'][1]['port'], 'PMA_PORT sets the port');
check_eq('MyDB', $cfg['Servers'][1]['verbose'], 'PMA_VERBOSE sets the verbose name');
check(!isset($cfg['Servers'][2]), 'PMA_HOST yields exactly one server');

/* 2b. PMA_HOST without PMA_VERBOSE / PMA_PORT must not emit notices. */
$cfg = load_config(array('PMA_HOST' => 'dbhost'));
check_eq('dbhost', $cfg['Servers'][1]['host'], 'PMA_HOST alone sets the host');
check(!isset($cfg['Servers'][1]['verbose']), 'missing PMA_VERBOSE leaves verbose unset');
check(!isset($cfg['Servers'][1]['port']), 'missing PMA_PORT leaves port unset');

/* 3. Multiple hosts via PMA_HOSTS / PMA_PORTS / PMA_VERBOSES. */
$cfg = load_config(array(
    'PMA_HOSTS' => 'db1,db2,db3',
    'PMA_PORTS' => '3306,3307',
    'PMA_VERBOSES' => 'One,Two',
));
check_eq('db1', $cfg['Servers'][1]['host'], 'first host from PMA_HOSTS');
check_eq('db2', $cfg['Servers'][2]['host'], 'second host from PMA_HOSTS');
check_eq('db3', $cfg['Servers'][3]['host'], 'third host from PMA_HOSTS');
check_eq('3306', $cfg['Servers'][1]['port'], 'first port from PMA_PORTS');
check_eq('3307', $cfg['Servers'][2]['port'], 'second port from PMA_PORTS');
check(!isset($cfg['Servers'][3]['port']), 'missing port is not set');
check_eq('One', $cfg['Servers'][1]['verbose'], 'first verbose name from PMA_VERBOSES');
check(!isset($cfg['Servers'][3]['verbose']), 'missing verbose name is not set');

/* 4. Config authentication via PMA_USER / PMA_PASSWORD. */
$cfg = load_config(array(
    'PMA_HOST' => 'dbhost',
    'PMA_USER' => 'admin',
    'PMA_PASSWORD' => 's3cret',
));
check_eq('config', $cfg['Servers'][1]['auth_type'], 'PMA_USER switches to config auth');
check_eq('admin', $cfg['Servers'][1]['user'], 'PMA_USER sets the user');
check_eq('s3cret', $cfg['Servers'][1]['password'], 'PMA_PASSWORD sets the password');

/* 5. PMA_USER without PMA_PASSWORD defaults the password to an empty string. */
$cfg = load_config(array(
    'PMA_HOST' => 'dbhost',
    'PMA_USER' => 'admin',
));
check_eq('', $cfg['Servers'][1]['password'], 'missing PMA_PASSWORD defaults to empty string');

/* 6. PMA_ARBITRARY=1 enables arbitrary server connections. */
$cfg = load_config(array('PMA_ARBITRARY' => '1'));
check_eq(true, $cfg['AllowArbitraryServer'], 'PMA_ARBITRARY=1 enables arbitrary servers');

/* 7. PMA_ABSOLUTE_URI is trimmed and applied. */
$cfg = load_config(array('PMA_ABSOLUTE_URI' => '  https://pma.example.net/  '));
check_eq('https://pma.example.net/', $cfg['PmaAbsoluteUri'], 'PMA_ABSOLUTE_URI is trimmed');

/* Clean up the sandbox. */
foreach (glob($configDir . '/*') as $file) {
    unlink($file);
}
rmdir($configDir);

if ($failures > 0) {
    echo "$failures of $tests checks failed\n";
    exit(1);
}

echo "All $tests checks passed\n";
exit(0);