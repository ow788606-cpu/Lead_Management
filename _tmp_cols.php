<?php
require 'api/db.php';
function showCols($pdo, $table){
  echo "[$table]\n";
  foreach($pdo->query("SHOW COLUMNS FROM `$table`") as $c){
    echo $c['Field']."\t".$c['Type']."\n";
  }
  echo "\n";
}
showCols($pdo, 'tags');
showCols($pdo, 'leads');
?>
