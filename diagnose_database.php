<?php
require_once 'api/db.php';

echo "<h2>Database Diagnostic Tool</h2>";

// Check MySQL version and engine support
try {
    $stmt = $pdo->query("SELECT VERSION() as version");
    $version = $stmt->fetch(PDO::FETCH_ASSOC)['version'];
    echo "<p>MySQL Version: $version</p>";
    
    $stmt = $pdo->query("SHOW ENGINES");
    $engines = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<h3>Available Storage Engines:</h3>";
    foreach ($engines as $engine) {
        echo "<p>{$engine['Engine']}: {$engine['Support']}</p>";
    }
} catch (Exception $e) {
    echo "<p>Error checking MySQL info: " . $e->getMessage() . "</p>";
}

// Check all tables in the database
echo "<h3>All Tables in Database:</h3>";
try {
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($tables as $table) {
        echo "<p>- $table</p>";
        
        // Get table info
        try {
            $stmt = $pdo->query("SHOW TABLE STATUS LIKE '$table'");
            $info = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($info) {
                echo "<p>&nbsp;&nbsp;Engine: {$info['Engine']}, Rows: {$info['Rows']}</p>";
            }
        } catch (Exception $e) {
            echo "<p>&nbsp;&nbsp;Error getting table info: " . $e->getMessage() . "</p>";
        }
    }
} catch (Exception $e) {
    echo "<p>Error listing tables: " . $e->getMessage() . "</p>";
}

// Try different approaches to fix the users table
echo "<h2>Attempting Multiple Fixes</h2>";

// Fix 1: Drop and recreate with MyISAM engine
echo "<h3>Fix 1: Recreate with MyISAM Engine</h3>";
try {
    $pdo->exec("DROP TABLE IF EXISTS users");
    echo "<p>✅ Dropped existing users table</p>";
    
    $sql = "CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4";
    
    $pdo->exec($sql);
    echo "<p>✅ Created users table with MyISAM engine</p>";
    
    // Test the table
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "<p>✅ Table query successful, current count: $count</p>";
    
    // Insert default user
    $stmt = $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
    $hashedPassword = password_hash('admin123', PASSWORD_DEFAULT);
    $stmt->execute(['admin', 'admin@example.com', $hashedPassword]);
    echo "<p>✅ Default admin user created successfully</p>";
    
    // Verify insertion
    $stmt = $pdo->query("SELECT username, email FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($users as $user) {
        echo "<p>User: {$user['username']} ({$user['email']})</p>";
    }
    
} catch (Exception $e) {
    echo "<p>❌ Fix 1 failed: " . $e->getMessage() . "</p>";
    
    // Fix 2: Try with no engine specification
    echo "<h3>Fix 2: Create with Default Engine</h3>";
    try {
        $pdo->exec("DROP TABLE IF EXISTS users");
        
        $sql = "CREATE TABLE users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(50) NOT NULL UNIQUE,
            email VARCHAR(100) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )";
        
        $pdo->exec($sql);
        echo "<p>✅ Created users table with default engine</p>";
        
        // Test and insert
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
        $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        echo "<p>✅ Table query successful</p>";
        
        $stmt = $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
        $hashedPassword = password_hash('admin123', PASSWORD_DEFAULT);
        $stmt->execute(['admin', 'admin@example.com', $hashedPassword]);
        echo "<p>✅ Default admin user created</p>";
        
    } catch (Exception $e2) {
        echo "<p>❌ Fix 2 also failed: " . $e2->getMessage() . "</p>";
        
        // Fix 3: Manual SQL approach
        echo "<h3>Fix 3: Manual SQL Commands</h3>";
        echo "<p>Please run these commands manually in phpMyAdmin:</p>";
        echo "<pre>";
        echo "USE lead;\n";
        echo "DROP TABLE IF EXISTS users;\n";
        echo "CREATE TABLE users (\n";
        echo "    id INT AUTO_INCREMENT PRIMARY KEY,\n";
        echo "    username VARCHAR(50) NOT NULL UNIQUE,\n";
        echo "    email VARCHAR(100) NOT NULL UNIQUE,\n";
        echo "    password VARCHAR(255) NOT NULL,\n";
        echo "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n";
        echo ");\n";
        echo "INSERT INTO users (username, email, password) VALUES \n";
        echo "('admin', 'admin@example.com', '" . password_hash('admin123', PASSWORD_DEFAULT) . "');\n";
        echo "</pre>";
    }
}

echo "<h2>Final Status Check</h2>";
try {
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "<p>✅ Users table is working! User count: $count</p>";
    
    if ($count > 0) {
        $stmt = $pdo->query("SELECT username, email FROM users LIMIT 5");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo "<h3>Current Users:</h3>";
        foreach ($users as $user) {
            echo "<p>- {$user['username']} ({$user['email']})</p>";
        }
    }
} catch (Exception $e) {
    echo "<p>❌ Users table still not working: " . $e->getMessage() . "</p>";
}
?>