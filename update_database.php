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

// Create task_details table
$sql2b = "CREATE TABLE IF NOT EXISTS task_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    task_source VARCHAR(32) NOT NULL DEFAULT 'tasks',
    comments LONGTEXT NULL,
    attachments LONGTEXT NULL,
    collaborators LONGTEXT NULL,
    activities LONGTEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_task_user_source (task_id, user_id, task_source),
    INDEX idx_task_user (task_id, user_id),
    INDEX idx_task_user_source (task_id, user_id, task_source)
)";

// Create task_notifications table
$sql2c = "CREATE TABLE IF NOT EXISTS task_notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    user_id INT NOT NULL,
    task_source VARCHAR(32) NOT NULL DEFAULT 'tasks',
    title VARCHAR(255) NOT NULL,
    message TEXT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_user (task_id, user_id),
    INDEX idx_user_read (user_id, is_read),
    INDEX idx_created_at (created_at)
)";

// Ensure task_details has task_source and correct unique key
$sql2b_add_source = "ALTER TABLE task_details ADD COLUMN IF NOT EXISTS task_source VARCHAR(32) NOT NULL DEFAULT 'tasks' AFTER user_id";
$sql2b_drop_unique = "ALTER TABLE task_details DROP INDEX uniq_task_user";
$sql2b_add_unique = "ALTER TABLE task_details ADD UNIQUE KEY uniq_task_user_source (task_id, user_id, task_source)";
$sql2b_add_index = "ALTER TABLE task_details ADD INDEX IF NOT EXISTS idx_task_user_source (task_id, user_id, task_source)";

// Ensure task_notifications has task_source
$sql2c_add_source = "ALTER TABLE task_notifications ADD COLUMN IF NOT EXISTS task_source VARCHAR(32) NOT NULL DEFAULT 'tasks' AFTER user_id";

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

    if ($conn->query($sql2b)) {
        echo "Task details table created successfully\n";
    }

    if ($conn->query($sql2b_add_source)) {
        echo "Task details task_source column ensured\n";
    }
    $hasOldIndex = $conn->query("SHOW INDEX FROM task_details WHERE Key_name = 'uniq_task_user'");
    if ($hasOldIndex && $hasOldIndex->num_rows > 0) {
        $conn->query($sql2b_drop_unique);
    }
    $hasNewUnique = $conn->query("SHOW INDEX FROM task_details WHERE Key_name = 'uniq_task_user_source'");
    if (!$hasNewUnique || $hasNewUnique->num_rows === 0) {
        if ($conn->query($sql2b_add_unique)) {
            echo "Task details unique index updated\n";
        }
    }
    $hasSourceIdx = $conn->query("SHOW INDEX FROM task_details WHERE Key_name = 'idx_task_user_source'");
    if (!$hasSourceIdx || $hasSourceIdx->num_rows === 0) {
        if ($conn->query($sql2b_add_index)) {
            echo "Task details source index ensured\n";
        }
    }

    if ($conn->query($sql2c)) {
        echo "Task notifications table created successfully\n";
    }

    if ($conn->query($sql2c_add_source)) {
        echo "Task notifications task_source column ensured\n";
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
