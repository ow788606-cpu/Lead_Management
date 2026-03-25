<?php
require_once 'api/db.php';

echo "<h2>Updating users table...</h2>";

try {
    $sql = "ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP NULL DEFAULT NULL";
    $pdo->exec($sql);
    echo "<p>✅ `deleted_at` column added to `users` table successfully.</p>";
} catch (Exception $e) {
    echo "<p>❌ Error adding `deleted_at` column: " . $e->getMessage() . "</p>";
}
