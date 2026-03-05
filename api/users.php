<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, PUT, OPTIONS');
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
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid user id']);
        exit;
    }

    $stmt = $conn->prepare(
        "SELECT user_Id, userName, email, full_name, phone, country, company_address, timezone, meta
         FROM users
         WHERE user_Id = ? AND deleted_at IS NULL
         LIMIT 1"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }

    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $row = $result ? $result->fetch_assoc() : null;
    $stmt->close();

    if (!$row) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }

    $meta = [];
    if (!empty($row['meta'])) {
        $decoded = json_decode((string)$row['meta'], true);
        if (is_array($decoded)) {
            $meta = $decoded;
        }
    }

    $profileMeta = [];
    if (isset($meta['profile']) && is_array($meta['profile'])) {
        $profileMeta = $meta['profile'];
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => (int)$row['user_Id'],
            'name' => (string)($row['full_name'] ?: $row['userName'] ?: ''),
            'location' => (string)($profileMeta['location'] ?? $row['timezone'] ?? ''),
            'email' => (string)($row['email'] ?? ''),
            'phone' => (string)($row['phone'] ?? ''),
            'address' => (string)($row['company_address'] ?? ''),
            'city' => (string)($profileMeta['city'] ?? ''),
            'zip' => (string)($profileMeta['zip'] ?? ''),
            'country' => (string)($row['country'] ?? ''),
        ],
    ]);
    exit;
}

if ($method === 'PUT') {
    $payload = json_decode(file_get_contents('php://input'), true);
    $userId = (int)($payload['user_id'] ?? 0);
    if ($userId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid user id']);
        exit;
    }

    $name = trim((string)($payload['name'] ?? ''));
    $location = trim((string)($payload['location'] ?? ''));
    $email = trim((string)($payload['email'] ?? ''));
    $phone = trim((string)($payload['phone'] ?? ''));
    $address = trim((string)($payload['address'] ?? ''));
    $city = trim((string)($payload['city'] ?? ''));
    $zip = trim((string)($payload['zip'] ?? ''));
    $country = trim((string)($payload['country'] ?? ''));

    if ($name === '' || $email === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Name and email are required']);
        exit;
    }

    $existingStmt = $conn->prepare("SELECT meta FROM users WHERE user_Id = ? AND deleted_at IS NULL LIMIT 1");
    if (!$existingStmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }
    $existingStmt->bind_param('i', $userId);
    $existingStmt->execute();
    $existingResult = $existingStmt->get_result();
    $existingUser = $existingResult ? $existingResult->fetch_assoc() : null;
    $existingStmt->close();

    if (!$existingUser) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }

    $meta = [];
    if (!empty($existingUser['meta'])) {
        $decoded = json_decode((string)$existingUser['meta'], true);
        if (is_array($decoded)) {
            $meta = $decoded;
        }
    }
    if (!isset($meta['profile']) || !is_array($meta['profile'])) {
        $meta['profile'] = [];
    }
    $meta['profile']['location'] = $location;
    $meta['profile']['city'] = $city;
    $meta['profile']['zip'] = $zip;
    $metaJson = json_encode($meta, JSON_UNESCAPED_UNICODE);

    $stmt = $conn->prepare(
        "UPDATE users
         SET full_name = ?, userName = ?, email = ?, phone = ?, company_address = ?, country = ?, meta = ?, updated_at = NOW()
         WHERE user_Id = ? AND deleted_at IS NULL"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Prepare failed']);
        exit;
    }

    $stmt->bind_param('sssssssi', $name, $name, $email, $phone, $address, $country, $metaJson, $userId);
    $ok = $stmt->execute();
    $stmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to update profile']);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
