<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/db.php';

if (!isset($_FILES['file']) || !is_uploaded_file($_FILES['file']['tmp_name'])) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'CSV file is required']);
    exit;
}

$ext = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
if ($ext !== 'csv') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Only CSV files are supported']);
    exit;
}

$userId = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 1;
$handle = fopen($_FILES['file']['tmp_name'], 'r');
if ($handle === false) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to read CSV']);
    exit;
}

$headers = fgetcsv($handle);
if ($headers === false) {
    fclose($handle);
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'CSV appears empty']);
    exit;
}

$normalizedHeaders = [];
foreach ($headers as $index => $header) {
    $key = strtolower(trim((string)$header));
    $key = str_replace([' ', '-', '/'], '_', $key);
    $normalizedHeaders[$index] = $key;
}

$inserted = 0;
$skipped = 0;
$errors = [];

$checkStmt = $conn->prepare(
    "SELECT id FROM contacts
     WHERE deleted_at IS NULL
       AND owner_user_id = ?
       AND ((email IS NOT NULL AND email <> '' AND email = ?) OR (contact_number IS NOT NULL AND contact_number <> '' AND contact_number = ?))
     LIMIT 1"
);

$insertStmt = $conn->prepare(
    "INSERT INTO contacts (
        owner_user_id, assigned_to, name, contact_number, contact_number2, email, address, country, state, city, zip,
        lead_source, remark, status, created_by, created_at, updated_at
    ) VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, NOW(), NOW())"
);

if (!$checkStmt || !$insertStmt) {
    fclose($handle);
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database prepare failed']);
    exit;
}

while (($row = fgetcsv($handle)) !== false) {
    $data = [];
    foreach ($normalizedHeaders as $idx => $header) {
        $data[$header] = isset($row[$idx]) ? trim((string)$row[$idx]) : '';
    }

    $name = (string)($data['name'] ?? '');
    $email = (string)($data['email'] ?? '');
    $contactNumber = (string)($data['contact_number'] ?? ($data['phone'] ?? ''));
    $contactNumber2 = (string)($data['contact_number2'] ?? ($data['phone_2'] ?? ''));
    $address = (string)($data['address'] ?? '');
    $country = (string)($data['country'] ?? '');
    $state = (string)($data['state'] ?? '');
    $city = (string)($data['city'] ?? '');
    $zip = (string)($data['zip'] ?? '');
    $leadSource = (string)($data['lead_source'] ?? '');
    $remark = (string)($data['remark'] ?? '');

    if ($name === '' || $contactNumber === '' || $address === '') {
        $skipped++;
        $errors[] = 'Skipped row due to missing required fields (name/contact_number/address).';
        continue;
    }

    $checkStmt->bind_param('iss', $userId, $email, $contactNumber);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();
    if ($checkResult && $checkResult->num_rows > 0) {
        $skipped++;
        continue;
    }

    $emailValue = $email === '' ? null : $email;
    $contactNumber2Value = $contactNumber2 === '' ? null : $contactNumber2;
    $countryValue = $country === '' ? null : $country;
    $stateValue = $state === '' ? null : $state;
    $cityValue = $city === '' ? null : $city;
    $zipValue = $zip === '' ? null : $zip;
    $leadSourceValue = $leadSource === '' ? null : $leadSource;
    $remarkValue = $remark === '' ? null : $remark;

    $insertStmt->bind_param(
        'isssssssssssi',
        $userId,
        $name,
        $contactNumber,
        $contactNumber2Value,
        $emailValue,
        $address,
        $countryValue,
        $stateValue,
        $cityValue,
        $zipValue,
        $leadSourceValue,
        $remarkValue,
        $userId
    );

    if ($insertStmt->execute()) {
        $inserted++;
    } else {
        $skipped++;
        $errors[] = 'Failed to insert a CSV row.';
    }
}

$checkStmt->close();
$insertStmt->close();
fclose($handle);

echo json_encode([
    'success' => true,
    'data' => [
        'inserted' => $inserted,
        'skipped' => $skipped,
        'errors' => $errors,
    ],
]);
