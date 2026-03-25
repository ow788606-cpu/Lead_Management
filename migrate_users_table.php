<?php
require_once 'api/db.php';

echo "<h2>User Table Migration</h2>";

function createUsersTable(PDO $pdo): void
{
    $sql = "CREATE TABLE IF NOT EXISTS users (
        user_Id INT AUTO_INCREMENT PRIMARY KEY,
        userName VARCHAR(50) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        user_secret VARCHAR(255) NOT NULL,
        full_name VARCHAR(100),
        phone VARCHAR(20),
        country VARCHAR(50),
        company_address VARCHAR(255),
        timezone VARCHAR(50),
        meta TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP NULL DEFAULT NULL
    )";
    $pdo->exec($sql);
    echo "<p>Users table created/verified.</p>";

    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $userCount = (int)$stmt->fetch(PDO::FETCH_ASSOC)['count'];
    if ($userCount === 0) {
        $stmt = $pdo->prepare("INSERT INTO users (userName, email, user_secret, full_name) VALUES (?, ?, ?, ?)");
        $stmt->execute(['admin', 'admin@example.com', password_hash('admin123', PASSWORD_DEFAULT), 'Admin User']);
        echo "<p>Default admin user created (user: admin, password: admin123).</p>";
    }
}

try {
    $tableCheck = $pdo->query("SHOW TABLES LIKE 'users'");
    if ($tableCheck->rowCount() === 0) {
        createUsersTable($pdo);
        exit;
    }

    $cols = $pdo->query("SHOW COLUMNS FROM users")->fetchAll(PDO::FETCH_COLUMN);
    $colSet = array_flip($cols);

    if (!isset($colSet['user_Id']) && isset($colSet['id'])) {
        $pdo->exec("ALTER TABLE users CHANGE COLUMN id user_Id INT AUTO_INCREMENT PRIMARY KEY");
        echo "<p>Renamed column id -> user_Id.</p>";
        $colSet['user_Id'] = true;
        unset($colSet['id']);
    }

    if (!isset($colSet['userName']) && isset($colSet['username'])) {
        $pdo->exec("ALTER TABLE users CHANGE COLUMN username userName VARCHAR(50) NOT NULL");
        echo "<p>Renamed column username -> userName.</p>";
        $colSet['userName'] = true;
        unset($colSet['username']);
    }

    if (!isset($colSet['user_secret']) && isset($colSet['password'])) {
        $pdo->exec("ALTER TABLE users CHANGE COLUMN password user_secret VARCHAR(255) NOT NULL");
        echo "<p>Renamed column password -> user_secret.</p>";
        $colSet['user_secret'] = true;
        unset($colSet['password']);
    }

    if (!isset($colSet['full_name'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN full_name VARCHAR(100) NULL");
        echo "<p>Added column full_name.</p>";
    }
    if (!isset($colSet['phone'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN phone VARCHAR(20) NULL");
        echo "<p>Added column phone.</p>";
    }
    if (!isset($colSet['country'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN country VARCHAR(50) NULL");
        echo "<p>Added column country.</p>";
    }
    if (!isset($colSet['company_address'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN company_address VARCHAR(255) NULL");
        echo "<p>Added column company_address.</p>";
    }
    if (!isset($colSet['timezone'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN timezone VARCHAR(50) NULL");
        echo "<p>Added column timezone.</p>";
    }
    if (!isset($colSet['meta'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN meta TEXT NULL");
        echo "<p>Added column meta.</p>";
    }
    if (!isset($colSet['created_at'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP");
        echo "<p>Added column created_at.</p>";
    }
    if (!isset($colSet['updated_at'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP");
        echo "<p>Added column updated_at.</p>";
    }
    if (!isset($colSet['deleted_at'])) {
        $pdo->exec("ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP NULL DEFAULT NULL");
        echo "<p>Added column deleted_at.</p>";
    }

    if (isset($colSet['userName'])) {
        $pdo->exec("UPDATE users SET userName = email WHERE userName IS NULL OR userName = ''");
    }

    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $userCount = (int)$stmt->fetch(PDO::FETCH_ASSOC)['count'];
    if ($userCount === 0) {
        $stmt = $pdo->prepare("INSERT INTO users (userName, email, user_secret, full_name) VALUES (?, ?, ?, ?)");
        $stmt->execute(['admin', 'admin@example.com', password_hash('admin123', PASSWORD_DEFAULT), 'Admin User']);
        echo "<p>Default admin user created (user: admin, password: admin123).</p>";
    }

    echo "<p>Migration complete.</p>";
} catch (Exception $e) {
    echo "<p>Migration failed: " . $e->getMessage() . "</p>";
}
