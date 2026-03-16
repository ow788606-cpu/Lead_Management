<?php
require_once 'api/db.php';

// Create activities table
$sql1 = "CREATE TABLE IF NOT EXISTS activities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    user_id INT NOT NULL,
    type VARCHAR(50) DEFAULT 'activity',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lead_user (lead_id, user_id),
    INDEX idx_created_at (created_at)
)";

// Create notes table
$sql2 = "CREATE TABLE IF NOT EXISTS notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lead_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lead_user (lead_id, user_id),
    INDEX idx_created_at (created_at)
)";

// Add lead_id to tasks table if not exists
$sql3 = "ALTER TABLE tasks ADD COLUMN IF NOT EXISTS lead_id INT NULL AFTER contact_id";
$sql4 = "ALTER TABLE tasks ADD INDEX IF NOT EXISTS idx_lead_id (lead_id)";

try {
    if ($conn->query($sql1)) {
        echo "Activities table created successfully\n";
    }
    
    if ($conn->query($sql2)) {
        echo "Notes table created successfully\n";
    }
    
    if ($conn->query($sql3)) {
        echo "Added lead_id column to tasks table\n";
    }
    
    if ($conn->query($sql4)) {
        echo "Added index for lead_id in tasks table\n";
    }
    
    echo "Database updated successfully!";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}

$conn->close();
?>