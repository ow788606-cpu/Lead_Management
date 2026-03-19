<?php
require_once 'api/db.php';

echo "<h2>Database Setup - Enhanced Version</h2>";

// First, let's check if the database exists and is accessible
try {
    $stmt = $pdo->query("SELECT DATABASE() as db_name");
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "<p>✅ Connected to database: " . $result['db_name'] . "</p>";
} catch (Exception $e) {
    echo "<p>❌ Database connection error: " . $e->getMessage() . "</p>";
    exit;
}

// Create users table with explicit engine specification
try {
    $sql = "CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
    
    $pdo->exec($sql);
    echo "<p>✅ users table created/verified with InnoDB engine</p>";
    
    // Verify the table was actually created
    $stmt = $pdo->query("SHOW TABLES LIKE 'users'");
    if ($stmt->rowCount() > 0) {
        echo "<p>✅ users table confirmed to exist</p>";
        
        // Check if any users exist
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
        $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        echo "<p>Current user count: $userCount</p>";
        
        if ($userCount == 0) {
            // Insert default user
            $stmt = $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
            $hashedPassword = password_hash('admin123', PASSWORD_DEFAULT);
            $stmt->execute(['admin', 'admin@example.com', $hashedPassword]);
            echo "<p>✅ Default admin user created (username: admin, password: admin123)</p>";
        } else {
            echo "<p>ℹ️ Users already exist, skipping default user creation</p>";
        }
    } else {
        echo "<p>❌ users table was not created successfully</p>";
    }
    
} catch (Exception $e) {
    echo "<p>❌ Error with users table: " . $e->getMessage() . "</p>";
}

// Create other required tables
$tables = [
    'lead_activities' => "CREATE TABLE IF NOT EXISTS lead_activities (
        id INT AUTO_INCREMENT PRIMARY KEY,
        lead_id INT NOT NULL,
        user_id INT NOT NULL DEFAULT 1,
        activity_type VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_lead_id (lead_id),
        INDEX idx_created_at (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
    
    'lead_notes' => "CREATE TABLE IF NOT EXISTS lead_notes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        lead_id INT NOT NULL,
        user_id INT NOT NULL DEFAULT 1,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_lead_id (lead_id),
        INDEX idx_created_at (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
    
    'lead_tasks' => "CREATE TABLE IF NOT EXISTS lead_tasks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        lead_id INT NOT NULL,
        user_id INT NOT NULL DEFAULT 1,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        priority ENUM('Low', 'Medium', 'High') DEFAULT 'Medium',
        due_date DATETIME NULL,
        is_completed TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_lead_id (lead_id),
        INDEX idx_due_date (due_date),
        INDEX idx_created_at (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"
];

foreach ($tables as $tableName => $sql) {
    try {
        $pdo->exec($sql);
        echo "<p>✅ $tableName table created/verified</p>";
    } catch (Exception $e) {
        echo "<p>❌ Error creating $tableName table: " . $e->getMessage() . "</p>";
    }
}

echo "<h2>Database Setup Complete</h2>";
echo "<p><a href='check_database.php'>Check Database Structure</a></p>";
echo "<p><a href='api/login.php'>Test Login API</a></p>";
?>