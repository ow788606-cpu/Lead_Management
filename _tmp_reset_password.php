<?php
require 'api/db.php';
$email = 'ow788606@gmail.com';
$newPass = '123456';
$hash = password_hash($newPass, PASSWORD_DEFAULT);
$stmt = $pdo->prepare('UPDATE users SET user_secret = ?, deleted_at = NULL WHERE email = ?');
$stmt->execute([$hash, $email]);
$rows = $stmt->rowCount();
echo "Updated rows: $rows\n";
$check = $pdo->prepare('SELECT user_Id, userName, email, deleted_at FROM users WHERE email = ?');
$check->execute([$email]);
$row = $check->fetch(PDO::FETCH_ASSOC);
var_export($row);
?>
