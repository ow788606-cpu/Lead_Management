<?php
require_once 'api/db.php';

try {
    // Create lead_activities table
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
    echo "✓ lead_activities table created/verified\n";

    // Create lead_notes table
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
    echo "✓ lead_notes table created/verified\n";

    // Create lead_tasks table
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
    echo "✓ lead_tasks table created/verified\n";

    echo "\n✅ All database tables have been created successfully!\n";
    
} catch (Exception $e) {
    echo "❌ Error creating tables: " . $e->getMessage() . "\n";
}
?>