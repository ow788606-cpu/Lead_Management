<?php
require_once 'api/db.php';

echo "<h2>Checking users table...</h2>";

try {
    $stmt = $pdo->query("SELECT * FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($users) === 0) {
        echo "<p>The `users` table is empty.</p>";
    } else {
        echo "<p>The `users` table contains the following users:</p>";
        echo "<ul>";
        foreach ($users as $user) {
            $name = $user['userName'] ?? $user['username'] ?? '';
            echo "<li>" . htmlspecialchars((string)$name) . " (" . htmlspecialchars((string)$user['email']) . ")</li>";
        }
        echo "</ul>";
    }
} catch (Exception $e) {
    echo "<p>❌ Error checking `users` table: " . $e->getMessage() . "</p>";
}
