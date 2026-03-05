<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    if ($userId <= 0) {
        echo json_encode(['success' => true, 'data' => []]);
        exit;
    }

    $sql = "SELECT id, name, email, contact_number, contact_number2, address, country, state, city, zip,
                   lead_source, remark, tags, created_at
            FROM contacts
            WHERE deleted_at IS NULL
              AND owner_user_id = $userId
            ORDER BY id DESC";
    $result = $conn->query($sql);
    if (!$result) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to fetch contacts']);
        exit;
    }

    $rows = [];
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }

    echo json_encode(['success' => true, 'data' => $rows]);
    exit;
}

if ($method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($payload['user_id'] ?? 1);
    $name = trim((string)($payload['name'] ?? ''));
    $email = trim((string)($payload['email'] ?? ''));
    $contactNumber = trim((string)($payload['contact_number'] ?? ''));
    $contactNumber2 = trim((string)($payload['contact_number2'] ?? ''));
    $address = trim((string)($payload['address'] ?? ''));
    $country = trim((string)($payload['country'] ?? ''));
    $state = trim((string)($payload['state'] ?? ''));
    $city = trim((string)($payload['city'] ?? ''));
    $zip = trim((string)($payload['zip'] ?? ''));
    $leadSource = trim((string)($payload['lead_source'] ?? ''));
    $remark = trim((string)($payload['remark'] ?? ''));

    if ($name === '' || $contactNumber === '' || $address === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Name, Contact Number and Address are required']);
        exit;
    }

    $stmt = $conn->prepare(
        "INSERT INTO contacts (
            owner_user_id, assigned_to, name, contact_number, contact_number2, email, address, country, state, city, zip,
            lead_source, remark, status, created_by, created_at, updated_at
        ) VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, NOW(), NOW())"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }

    $contactNumber2Value = $contactNumber2 === '' ? null : $contactNumber2;
    $emailValue = $email === '' ? null : $email;
    $countryValue = $country === '' ? null : $country;
    $stateValue = $state === '' ? null : $state;
    $cityValue = $city === '' ? null : $city;
    $zipValue = $zip === '' ? null : $zip;
    $leadSourceValue = $leadSource === '' ? null : $leadSource;
    $remarkValue = $remark === '' ? null : $remark;

    $stmt->bind_param(
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
    $ok = $stmt->execute();
    $newId = $conn->insert_id;
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create contact']);
        exit;
    }

    http_response_code(201);
    echo json_encode(['success' => true, 'data' => ['id' => $newId]]);
    exit;
}

if ($method === 'PUT') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($payload['user_id'] ?? 0);
    $id = (int)($payload['id'] ?? 0);
    if ($id <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid contact id']);
        exit;
    }

    $name = trim((string)($payload['name'] ?? ''));
    $email = trim((string)($payload['email'] ?? ''));
    $contactNumber = trim((string)($payload['contact_number'] ?? ''));
    $contactNumber2 = trim((string)($payload['contact_number2'] ?? ''));
    $address = trim((string)($payload['address'] ?? ''));
    $country = trim((string)($payload['country'] ?? ''));
    $state = trim((string)($payload['state'] ?? ''));
    $city = trim((string)($payload['city'] ?? ''));
    $zip = trim((string)($payload['zip'] ?? ''));
    $leadSource = trim((string)($payload['lead_source'] ?? ''));
    $remark = trim((string)($payload['remark'] ?? ''));

    if ($name === '' || $contactNumber === '' || $address === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Name, Contact Number and Address are required']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE contacts
         SET name = ?, email = ?, contact_number = ?, contact_number2 = ?, address = ?, country = ?, state = ?, city = ?, zip = ?,
             lead_source = ?, remark = ?, updated_at = NOW()
         WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }

    $contactNumber2Value = $contactNumber2 === '' ? null : $contactNumber2;
    $emailValue = $email === '' ? null : $email;
    $countryValue = $country === '' ? null : $country;
    $stateValue = $state === '' ? null : $state;
    $cityValue = $city === '' ? null : $city;
    $zipValue = $zip === '' ? null : $zip;
    $leadSourceValue = $leadSource === '' ? null : $leadSource;
    $remarkValue = $remark === '' ? null : $remark;

    $stmt->bind_param(
        'sssssssssssii',
        $name,
        $emailValue,
        $contactNumber,
        $contactNumber2Value,
        $address,
        $countryValue,
        $stateValue,
        $cityValue,
        $zipValue,
        $leadSourceValue,
        $remarkValue,
        $id,
        $userId
    );
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update contact']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

if ($method === 'DELETE') {
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0 || $userId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid contact id']);
        exit;
    }

    $stmt = $conn->prepare("UPDATE contacts SET deleted_at = NOW(), updated_at = NOW() WHERE id = ? AND owner_user_id = ?");
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }
    $stmt->bind_param('ii', $id, $userId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to delete contact']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
