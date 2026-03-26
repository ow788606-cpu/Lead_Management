<?php
require 'api/db.php';
$stmt = $pdo->query("SELECT id, name FROM tags ORDER BY id ASC LIMIT 20");
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
foreach($rows as $r){ echo $r['id']."\t".$r['name']."\n"; }
?>
