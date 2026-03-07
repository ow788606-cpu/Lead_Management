<?php
$c = new mysqli('127.0.0.1', 'root', '', 'lead');
if ($c->connect_error) {
  fwrite(STDERR, $c->connect_error . PHP_EOL);
  exit(1);
}
$r = $c->query('SHOW COLUMNS FROM status');
while ($row = $r->fetch_assoc()) {
  echo $row['Field'] . PHP_EOL;
}
