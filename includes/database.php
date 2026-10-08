<?php
declare(strict_types=1);

function database(): PDO
{
    static $connection = null;

    if ($connection instanceof PDO) {
        return $connection;
    }

    $host = getenv('NOTFLIX_DB_HOST') ?: '127.0.0.1';
    $port = getenv('NOTFLIX_DB_PORT') ?: '3306';
    $name = getenv('NOTFLIX_DB_NAME') ?: 'notflix_db';
    $user = getenv('NOTFLIX_DB_USER') ?: 'root';
    $password = getenv('NOTFLIX_DB_PASSWORD') ?: '';

    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $name);
    $connection = new PDO($dsn, $user, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    return $connection;
}
