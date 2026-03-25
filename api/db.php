<?php
declare(strict_types=1);
define('API_SECRET', 'sWDEqr32E6T578A8@0S2sD1!WDERF');
define('APP_TOKEN', 'CloopApp@2026#SecretKey!XyZ');

$dbHost = '127.0.0.1';
$dbName = 'lead';
$dbUser = 'root';
$dbPass = '';

$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}
$conn->set_charset('utf8mb4');

try {
    $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4", $dbUser, $dbPass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}
function generateApiToken(int $userId, string $userType = 'personal', int $ownerUserId = 0): string
{
    if ($ownerUserId <= 0) {
        $ownerUserId = $userId;
    }
    $timestamp = time();
    $payload   = $userId . '|' . $userType . '|' . $ownerUserId . '|' . $timestamp;
    $signature = hash_hmac('sha256', $payload, API_SECRET);
    return base64_encode($payload . '|' . $signature);
}
function validateApiToken(string $token): ?array
{
    $decoded = base64_decode($token, true);
    if ($decoded === false) {
        return null;
    }
    $lastPipe  = strrpos($decoded, '|');
    if ($lastPipe === false) {
        return null;
    }
    $signature = substr($decoded, $lastPipe + 1);
    $payload   = substr($decoded, 0, $lastPipe);

    $expectedSig = hash_hmac('sha256', $payload, API_SECRET);
    if (!hash_equals($expectedSig, $signature)) {
        return null;
    }

    $parts = explode('|', $payload, 4);
    if (count($parts) !== 4) {
        return null;
    }

    [$userId, $userType, $ownerUserId, $timestamp] = $parts;
    $userId      = (int)$userId;
    $ownerUserId = (int)$ownerUserId;

    if ($userId <= 0 || !ctype_digit((string)$timestamp)) {
        return null;
    }
    if ((time() - (int)$timestamp) > 86400 * 90) {
        return null;
    }

    return [
        'user_id'        => $userId,
        'user_type'      => $userType,
        'owner_user_id'  => $ownerUserId > 0 ? $ownerUserId : $userId,
    ];
}
 
function requireApiAuth(): array
{
    // --- 1. Check static app token ---
    $token = null;

    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
    if (preg_match('/^Bearer\s+(\S+)$/i', trim($authHeader), $m)) {
        $token = $m[1];
    }
    if ($token === null && !empty($_SERVER['HTTP_X_API_TOKEN'])) {
        $token = trim($_SERVER['HTTP_X_API_TOKEN']);
    }
    if ($token === null && function_exists('getallheaders')) {
        $headers = getallheaders();
        foreach ($headers as $name => $value) {
            $key = strtolower((string)$name);
            if ($key === 'authorization' && preg_match('/^Bearer\s+(\S+)$/i', trim((string)$value), $m)) {
                $token = $m[1];
                break;
            }
            if ($key === 'x-api-token' && trim((string)$value) !== '') {
                $token = trim((string)$value);
                break;
            }
        }
    }
    if ($token === null && isset($_GET['token']) && $_GET['token'] !== '') {
        $token = trim($_GET['token']);
    }

    if ($token === null || $token === '') {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit;
    }

    if (!hash_equals(APP_TOKEN, $token)) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token']);
        exit;
    }

    // --- 2. Get user_id from X-User-Id header or request body ---
    $userId = 0;

    if (!empty($_SERVER['HTTP_X_USER_ID'])) {
        $userId = (int)$_SERVER['HTTP_X_USER_ID'];
    } elseif (function_exists('getallheaders')) {
        $headers = getallheaders();
        foreach ($headers as $name => $value) {
            if (strtolower((string)$name) === 'x-user-id') {
                $userId = (int)$value;
                break;
            }
        }
    }

    if ($userId <= 0) {
        $body = json_decode(file_get_contents('php://input'), true);
        if (!empty($body['user_id'])) {
            $userId = (int)$body['user_id'];
        }
    }

    if ($userId <= 0 && isset($_GET['user_id'])) {
        $userId = (int)$_GET['user_id'];
    }

    if ($userId <= 0) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'user_id required']);
        exit;
    }

    // --- 3. Load user info from DB ---
    global $conn;
    $stmt = $conn->prepare(
        "SELECT user_Id, user_type, company_owner_user_id FROM users WHERE user_Id = ? AND deleted_at IS NULL LIMIT 1"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'User not found']);
        exit;
    }

    $userType    = (string)($row['user_type'] ?? 'personal');
    $ownerUserId = (int)($row['company_owner_user_id'] ?? 0);
    if ($ownerUserId <= 0) {
        $ownerUserId = $userId;
    }

    return [
        'user_id'       => $userId,
        'user_type'     => $userType,
        'owner_user_id' => $ownerUserId,
    ];
}
