<?php
require_once 'api/db.php';

echo "<h2>Database Table Check</h2>";

// Check if tables exist
$tables = ['leads', 'lead_activities', 'lead_notes', 'lead_tasks', 'users'];

foreach ($tables as $table) {
    try {
        $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
        $exists = $stmt->rowCount() > 0;
        
        if ($exists) {
            echo "<h3>✅ Table '$table' exists</h3>";
            
            // Show table structure
            $stmt = $pdo->query("DESCRIBE $table");
            $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo "<table border='1' style='border-collapse: collapse; margin: 10px 0;'>";
            echo "<tr><th>Column</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
            foreach ($columns as $column) {
                echo "<tr>";
                echo "<td>{$column['Field']}</td>";
                echo "<td>{$column['Type']}</td>";
                echo "<td>{$column['Null']}</td>";
                echo "<td>{$column['Key']}</td>";
                echo "<td>{$column['Default']}</td>";
                echo "</tr>";
            }
            echo "</table>";
            
            // Show sample data count
            $stmt = $pdo->query("SELECT COUNT(*) as count FROM $table");
            $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            echo "<p>Records: $count</p>";
            
        } else {
            echo "<h3>❌ Table '$table' does not exist</h3>";
        }
    } catch (Exception $e) {
        echo "<h3>❌ Error checking table '$table': " . $e->getMessage() . "</h3>";
    }
}

// Test a specific lead's data
echo "<h2>Sample Lead Data Test</h2>";
try {
    $stmt = $pdo->query("SELECT id, description FROM leads LIMIT 5");
    $leads = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (!empty($leads)) {
        echo "<h3>Sample Leads:</h3>";
        foreach ($leads as $lead) {
            echo "<p>Lead ID: {$lead['id']}, Description: " . substr($lead['description'], 0, 50) . "...</p>";
            
            // Check activities for this lead
            $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM lead_activities WHERE lead_id = ?");
            $stmt->execute([$lead['id']]);
            $activityCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            // Check notes for this lead
            $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM lead_notes WHERE lead_id = ?");
            $stmt->execute([$lead['id']]);
            $noteCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            // Check tasks for this lead
            $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM lead_tasks WHERE lead_id = ?");
            $stmt->execute([$lead['id']]);
            $taskCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
            
            echo "<p>&nbsp;&nbsp;Activities: $activityCount, Notes: $noteCount, Tasks: $taskCount</p>";
        }
    } else {
        echo "<p>No leads found in database</p>";
    }
} catch (Exception $e) {
    echo "<p>Error: " . $e->getMessage() . "</p>";
}
?>