<?php
// Setup script to ensure notification system works properly
require_once 'db.php';

echo "<h2>Notification System Setup</h2>";

try {
    // 1. Check and add scheduled_at column to lead_activities
    echo "<h3>1. Checking lead_activities table...</h3>";
    $checkColumn = $pdo->query("SHOW COLUMNS FROM lead_activities LIKE 'scheduled_at'");
    
    if ($checkColumn->rowCount() == 0) {
        $pdo->exec("ALTER TABLE lead_activities ADD COLUMN scheduled_at DATETIME NULL AFTER description");
        echo "<p style='color: green;'>✅ Added 'scheduled_at' column to lead_activities table</p>";
    } else {
        echo "<p style='color: blue;'>ℹ️ Column 'scheduled_at' already exists</p>";
    }
    
    // 2. Show current table structure
    echo "<h3>2. Current lead_activities structure:</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Default</th></tr>";
    $columns = $pdo->query("SHOW COLUMNS FROM lead_activities");
    while ($column = $columns->fetch()) {
        echo "<tr>";
        echo "<td>{$column['Field']}</td>";
        echo "<td>{$column['Type']}</td>";
        echo "<td>{$column['Null']}</td>";
        echo "<td>" . ($column['Default'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // 3. Show sample activities with scheduled_at
    echo "<h3>3. Activities with scheduled_at:</h3>";
    $stmt = $pdo->query("SELECT id, lead_id, activity_type, scheduled_at, created_at FROM lead_activities WHERE scheduled_at IS NOT NULL ORDER BY scheduled_at DESC LIMIT 10");
    $activities = $stmt->fetchAll();
    
    if (count($activities) > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Lead ID</th><th>Activity Type</th><th>Scheduled At</th><th>Created At</th></tr>";
        foreach ($activities as $activity) {
            echo "<tr>";
            echo "<td>{$activity['id']}</td>";
            echo "<td>{$activity['lead_id']}</td>";
            echo "<td>{$activity['activity_type']}</td>";
            echo "<td>{$activity['scheduled_at']}</td>";
            echo "<td>{$activity['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color: orange;'>⚠️ No activities with scheduled_at found</p>";
    }
    
    echo "<h3>✅ Setup Complete!</h3>";
    echo "<p>The notification system is now ready. Create activities with date/time to test notifications.</p>";
    
} catch (Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}
?>
