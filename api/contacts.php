<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Api-Token, X-User-Id');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$auth   = requireApiAuth();
$authId = $auth['user_id'];        // authenticated user
$ownerId = $auth['owner_user_id']; // company owner (same as $authId unless employee)

$method = $_SERVER['REQUEST_METHOD'];

// ─── GET: list contacts ───────────────────────────────────────────────────────
if ($method === 'GET') {
    $stmt = $conn->prepare(
        "SELECT id, name, email, contact_number, contact_number2, address, country, state, city, zip,
                lead_source, remark, tags, created_at
         FROM contacts
         WHERE deleted_at IS NULL
           AND owner_user_id = ?
         ORDER BY id DESC"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('i', $ownerId);
    $stmt->execute();
    $result = $stmt->get_result();
    $rows   = [];
    while ($row = $result->fetch_assoc()) {
        $rows[] = $row;
    }
    $stmt->close();

    echo json_encode(['success' => true, 'data' => $rows]);
    exit;
}

// ─── POST: create contact ─────────────────────────────────────────────────────
if ($method === 'POST') {
    $payload        = json_decode(file_get_contents('php://input'), true);
    $name           = trim((string)($payload['name'] ?? ''));
    $email          = trim((string)($payload['email'] ?? ''));
    $contactNumber  = trim((string)($payload['contact_number'] ?? ''));
    $contactNumber2 = trim((string)($payload['contact_number2'] ?? ''));
    $address        = trim((string)($payload['address'] ?? ''));
    $country        = trim((string)($payload['country'] ?? ''));
    $state          = trim((string)($payload['state'] ?? ''));
    $city           = trim((string)($payload['city'] ?? ''));
    $zip            = trim((string)($payload['zip'] ?? ''));
    $leadSource     = trim((string)($payload['lead_source'] ?? ''));
    $remark         = trim((string)($payload['remark'] ?? ''));

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
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $emailValue         = $email === '' ? null : $email;
    $contactNumber2Val  = $contactNumber2 === '' ? null : $contactNumber2;
    $countryValue       = $country === '' ? null : $country;
    $stateValue         = $state === '' ? null : $state;
    $cityValue          = $city === '' ? null : $city;
    $zipValue           = $zip === '' ? null : $zip;
    $leadSourceValue    = $leadSource === '' ? null : $leadSource;
    $remarkValue        = $remark === '' ? null : $remark;

    $stmt->bind_param(
        'isssssssssssi',
        $ownerId,
        $name,
        $contactNumber,
        $contactNumber2Val,
        $emailValue,
        $address,
        $countryValue,
        $stateValue,
        $cityValue,
        $zipValue,
        $leadSourceValue,
        $remarkValue,
        $ownerId
    );
    $ok    = $stmt->execute();
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

// ─── PUT: update contact ──────────────────────────────────────────────────────
if ($method === 'PUT') {
    $payload        = json_decode(file_get_contents('php://input'), true);
    $id             = (int)($payload['id'] ?? 0);
    if ($id <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid contact id']);
        exit;
    }

    $name           = trim((string)($payload['name'] ?? ''));
    $email          = trim((string)($payload['email'] ?? ''));
    $contactNumber  = trim((string)($payload['contact_number'] ?? ''));
    $contactNumber2 = trim((string)($payload['contact_number2'] ?? ''));
    $address        = trim((string)($payload['address'] ?? ''));
    $country        = trim((string)($payload['country'] ?? ''));
    $state          = trim((string)($payload['state'] ?? ''));
    $city           = trim((string)($payload['city'] ?? ''));
    $zip            = trim((string)($payload['zip'] ?? ''));
    $leadSource     = trim((string)($payload['lead_source'] ?? ''));
    $remark         = trim((string)($payload['remark'] ?? ''));

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
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $emailValue        = $email === '' ? null : $email;
    $contactNumber2Val = $contactNumber2 === '' ? null : $contactNumber2;
    $countryValue      = $country === '' ? null : $country;
    $stateValue        = $state === '' ? null : $state;
    $cityValue         = $city === '' ? null : $city;
    $zipValue          = $zip === '' ? null : $zip;
    $leadSourceValue   = $leadSource === '' ? null : $leadSource;
    $remarkValue       = $remark === '' ? null : $remark;

    $stmt->bind_param(
        'sssssssssssii',
        $name,
        $emailValue,
        $contactNumber,
        $contactNumber2Val,
        $address,
        $countryValue,
        $stateValue,
        $cityValue,
        $zipValue,
        $leadSourceValue,
        $remarkValue,
        $id,
        $ownerId
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

// ─── DELETE: soft-delete contact ─────────────────────────────────────────────
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid contact id']);
        exit;
    }

    $stmt = $conn->prepare(
        "UPDATE contacts SET deleted_at = NOW(), updated_at = NOW()
         WHERE id = ? AND owner_user_id = ?"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('ii', $id, $ownerId);
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
