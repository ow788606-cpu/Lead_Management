<?php
// Database migration script to add scheduled_at column to lead_activities table
require_once 'db.php';

try {
    // Check if the column already exists
    $checkColumn = $pdo->query("SHOW COLUMNS FROM lead_activities LIKE 'scheduled_at'");
    
    if ($checkColumn->rowCount() == 0) {
        // Add the scheduled_at column
        $pdo->exec("ALTER TABLE lead_activities ADD COLUMN scheduled_at DATETIME NULL AFTER description");
        echo "✅ Successfully added 'scheduled_at' column to lead_activities table\n";
    } else {
        echo "ℹ️ Column 'scheduled_at' already exists in lead_activities table\n";
    }
    
    // Show the updated table structure
    echo "\n📋 Current lead_activities table structure:\n";
    $columns = $pdo->query("SHOW COLUMNS FROM lead_activities");
    while ($column = $columns->fetch()) {
        echo "- {$column['Field']} ({$column['Type']}) " . 
             ($column['Null'] == 'YES' ? 'NULL' : 'NOT NULL') . 
             ($column['Default'] ? " DEFAULT {$column['Default']}" : '') . "\n";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
?>