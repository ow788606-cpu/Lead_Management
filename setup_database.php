<?php
require_once 'api/db.php';

echo "<h2>Creating Missing Database Tables</h2>";

// Create lead_activities table
try {
    $sql = "CREATE TABLE IF NOT EXISTS lead_activities (
        id INT AUTO_INCREMENT PRIMARY KEY,
        lead_id INT NOT NULL,
        user_id INT NOT NULL DEFAULT 1,
        activity_type VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_lead_id (lead_id),
        INDEX idx_created_at (created_at)
    )";
    $pdo->exec($sql);
    echo "<p>✅ lead_activities table created/verified</p>";
} catch (Exception $e) {
    echo "<p>❌ Error creating lead_activities table: " . $e->getMessage() . "</p>";
}

// Create lead_notes table
try {
    $sql = "CREATE TABLE IF NOT EXISTS lead_notes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        lead_id INT NOT NULL,
        user_id INT NOT NULL DEFAULT 1,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_lead_id (lead_id),
        INDEX idx_created_at (created_at)
    )";
    $pdo->exec($sql);
    echo "<p>✅ lead_notes table created/verified</p>";
} catch (Exception $e) {
    echo "<p>❌ Error creating lead_notes table: " . $e->getMessage() . "</p>";
}

// Create lead_tasks table
try {
    $sql = "CREATE TABLE IF NOT EXISTS lead_tasks (
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
    )";
    $pdo->exec($sql);
    echo "<p>✅ lead_tasks table created/verified</p>";
} catch (Exception $e) {
    echo "<p>❌ Error creating lead_tasks table: " . $e->getMessage() . "</p>";
}

// Create users table if it doesn't exist
try {
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
    echo "<p>✅ users table created/verified</p>";
    
    // Insert a default user if none exists
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    if ($userCount == 0) {
        $stmt = $pdo->prepare("INSERT INTO users (userName, email, user_secret, full_name) VALUES (?, ?, ?, ?)");
        $stmt->execute(['admin', 'admin@example.com', password_hash('admin123', PASSWORD_DEFAULT), 'Admin User']);
        echo "<p>✅ Default admin user created (user: admin, password: admin123)</p>";
    }
    
} catch (Exception $e) {
    echo "<p>❌ Error creating users table: " . $e->getMessage() . "</p>";
}

echo "<h2>Database Setup Complete</h2>";
echo "<p><a href='check_database.php'>Check Database Structure</a></p>";
?>
