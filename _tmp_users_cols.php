<?php
require 'api/db.php';
echo "FIELD\tTYPE\tNULL\tDEFAULT\n";
foreach($pdo->query("SHOW COLUMNS FROM users") as $c){
  echo $c['Field']."\t".$c['Type']."\t".$c['Null']."\t".(is_null($c['Default'])?'NULL':$c['Default'])."\n";
}
?>
