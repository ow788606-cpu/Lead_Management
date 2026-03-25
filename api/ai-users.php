<?php
/**
 * AI Users Autocomplete Endpoint
 * ================================
 * GET /api/ai-users.php?q=partial_name
 * Returns JSON array of { id, full_name } for users in this account.
 * Used by the AI Assistant chat UI when typing "assigned to ...".
 */
declare(strict_types=1);

header('Content-Type: application/json');

require_once __DIR__ . '/../config.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (empty($_SESSION['user_id'])) {
    echo json_encode([]);
    exit;
}

$userId   = (int)$_SESSION['user_id'];
$userType = $_SESSION['user_type'] ?? 'business';
$ownerId  = ($userType === 'employee' && !empty($_SESSION['company_owner_user_id']))
    ? (int)$_SESSION['company_owner_user_id']
    : $userId;

$con = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($con->connect_errno) {
    echo json_encode([]);
    exit;
}
$con->set_charset(DB_CHARSET);

$q = isset($_GET['q']) ? trim($_GET['q']) : '';

if ($q !== '') {
    $stmt = $con->prepare(
        "SELECT user_Id AS id, full_name
         FROM users
         WHERE (company_owner_user_id = ? OR user_Id = ?)
           AND current_status = 'active'
           AND deleted_at IS NULL
           AND full_name LIKE ?
         ORDER BY full_name ASC
         LIMIT 10"
    );
    $like = '%' . $q . '%';
    $stmt->bind_param('iis', $ownerId, $ownerId, $like);
} else {
    $stmt = $con->prepare(
        "SELECT user_Id AS id, full_name
         FROM users
         WHERE (company_owner_user_id = ? OR user_Id = ?)
           AND current_status = 'active'
           AND deleted_at IS NULL
         ORDER BY full_name ASC
         LIMIT 20"
    );
    $stmt->bind_param('ii', $ownerId, $ownerId);
}

$stmt->execute();
$res   = $stmt->get_result();
$users = [];
while ($row = $res->fetch_assoc()) {
    $users[] = $row;
}
$stmt->close();
$con->close();

echo json_encode($users);
