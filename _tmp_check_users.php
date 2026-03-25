<?php
require 'api/db.php';
echo "COLUMNS\n";
foreach($pdo->query("SHOW COLUMNS FROM users") as $c){
  echo $c['Field']."\t".$c['Type']."\n";
}
echo "\nUSERS\n";
$stmt=$pdo->query("SELECT user_Id, userName, email, user_secret, deleted_at FROM users LIMIT 5");
foreach($stmt as $row){
  echo $row['user_Id']."\t".$row['userName']."\t".$row['email']."\t".substr($row['user_secret'],0,20)."...\t".(is_null($row['deleted_at']) ? "NULL" : $row['deleted_at'])."\n";
}
?>
