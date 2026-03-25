<?php
require 'api/db.php';
foreach($pdo->query('SHOW COLUMNS FROM tasks') as $c){
  echo $c['Field']."\t".$c['Type']."\n";
}
?>
