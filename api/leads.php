<?php
declare(strict_types=1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Api-Token, X-User-Id');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/db.php';

$auth     = requireApiAuth();
$authId   = $auth['user_id'];
$userType = $auth['user_type'];
$ownerId  = $auth['owner_user_id'];

$method = $_SERVER['REQUEST_METHOD'];

// ─── GET: list leads ──────────────────────────────────────────────────────────
if ($method === 'GET') {
    // Match web logic: business → owner_user_id, employee → assigned_to, personal → created_by
    if ($userType === 'employee') {
        $filterSql   = 'l.assigned_to = ?';
        $filterParam = $authId;
    } elseif ($userType === 'personal') {
        $filterSql   = 'l.created_by = ?';
        $filterParam = $authId;
    } else {
        // business (default)
        $filterSql   = 'l.owner_user_id = ?';
        $filterParam = $authId;
    }

    $stmt = $conn->prepare(
        "SELECT
             l.id,
             c.name  AS contact_name,
             c.email,
             c.contact_number AS phone,
             COALESCE(GROUP_CONCAT(DISTINCT s.service_name ORDER BY s.service_id SEPARATOR ', '), '') AS service_name,
             l.tags,
             l.description,
             l.next_followup_at,
             l.created_at,
             l.status,
             st.name AS status_name
         FROM leads l
         LEFT JOIN contacts c  ON c.id = l.contact_id
         LEFT JOIN services s  ON FIND_IN_SET(s.service_id, l.service_id) > 0
         LEFT JOIN status   st ON st.id = l.status
         WHERE l.deleted_at IS NULL
           AND {$filterSql}
         GROUP BY l.id, c.name, c.email, c.contact_number, l.tags, l.description,
                  l.next_followup_at, l.created_at, l.status, st.name
         ORDER BY l.id DESC"
    );
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $stmt->bind_param('i', $filterParam);
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

// ─── POST: create lead or update status ──────────────────────────────────────
if ($method === 'POST') {
    $payload = json_decode(file_get_contents('php://input'), true);

    // Update lead status
    if (isset($payload['action']) && $payload['action'] === 'update_status') {
        $leadId   = (int)($payload['lead_id'] ?? 0);
        $statusId = (int)($payload['status_id'] ?? 1);

        if ($leadId <= 0) {
            http_response_code(422);
            echo json_encode(['success' => false, 'message' => 'Invalid lead id']);
            exit;
        }

        // Verify lead belongs to the authenticated user
        $verifyStmt = $conn->prepare(
            "SELECT id FROM leads
             WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL
             LIMIT 1"
        );
        if (!$verifyStmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $verifyStmt->bind_param('ii', $leadId, $ownerId);
        $verifyStmt->execute();
        $lead = $verifyStmt->get_result()->fetch_assoc();
        $verifyStmt->close();

        if (!$lead) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Lead not found']);
            exit;
        }

        $updateStmt = $conn->prepare(
            "UPDATE leads SET status = ?, updated_at = NOW()
             WHERE id = ? AND owner_user_id = ?"
        );
        if (!$updateStmt) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Server error']);
            exit;
        }
        $updateStmt->bind_param('iii', $statusId, $leadId, $ownerId);
        $ok = $updateStmt->execute();
        $updateStmt->close();

        if (!$ok) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update lead status']);
            exit;
        }

        echo json_encode(['success' => true, 'message' => 'Lead status updated successfully']);
        exit;
    }

    // Create new lead
    $contactId       = (int)($payload['contact_id'] ?? 0);
    $serviceName     = trim((string)($payload['service_name'] ?? ''));
    $tags            = trim((string)($payload['tags'] ?? ''));
    $description     = trim((string)($payload['description'] ?? ''));
    $nextFollowUpAt  = trim((string)($payload['next_followup_at'] ?? ''));
    $statusId        = (int)($payload['status_id'] ?? 1);

    if ($contactId <= 0) {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'Invalid contact id']);
        exit;
    }

    // Verify contact belongs to owner
    $contactStmt = $conn->prepare(
        "SELECT id FROM contacts
         WHERE id = ? AND owner_user_id = ? AND deleted_at IS NULL
         LIMIT 1"
    );
    if (!$contactStmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }
    $contactStmt->bind_param('ii', $contactId, $ownerId);
    $contactStmt->execute();
    $contact = $contactStmt->get_result()->fetch_assoc();
    $contactStmt->close();

    if (!$contact) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Contact not found']);
        exit;
    }

    $serviceIdValue = null;
    if ($serviceName !== '') {
        $serviceStmt = $conn->prepare(
            "SELECT service_id FROM services
             WHERE service_user_id = ? AND deleted_at IS NULL AND service_name = ?
             ORDER BY service_id DESC LIMIT 1"
        );
        if ($serviceStmt) {
            $serviceStmt->bind_param('is', $ownerId, $serviceName);
            $serviceStmt->execute();
            $service = $serviceStmt->get_result()->fetch_assoc();
            $serviceStmt->close();
            if ($service && isset($service['service_id'])) {
                $serviceIdValue = (string)$service['service_id'];
            }
        }
    }

    $nextFollowUpAtValue = null;
    if ($nextFollowUpAt !== '') {
        $dt = date_create($nextFollowUpAt);
        if ($dt !== false) {
            $nextFollowUpAtValue = $dt->format('Y-m-d H:i:s');
        }
    }

    $tagsValue        = $tags === '' ? null : $tags;
    $descriptionValue = $description === '' ? null : $description;

    $insertStmt = $conn->prepare(
        "INSERT INTO leads (
             owner_user_id, created_by, assigned_to, contact_id, service_id,
             description, tags, next_followup_at, status, created_at, updated_at
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())"
    );
    if (!$insertStmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Server error']);
        exit;
    }

    $insertStmt->bind_param(
        'iiiissssi',
        $ownerId,
        $authId,
        $authId,
        $contactId,
        $serviceIdValue,
        $descriptionValue,
        $tagsValue,
        $nextFollowUpAtValue,
        $statusId
    );
    $ok    = $insertStmt->execute();
    $newId = $conn->insert_id;
    $insertStmt->close();

    if (!$ok) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create lead']);
        exit;
    }

    http_response_code(201);
    echo json_encode(['success' => true, 'data' => ['id' => $newId]]);
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed']);
