<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            handleGet();
            break;
        case 'POST':
            handlePost();
            break;
        case 'PUT':
            handlePut();
            break;
        case 'DELETE':
            handleDelete();
            break;
        default:
            http_response_code(405);
            echo json_encode(['success' => false, 'message' => 'Method not allowed']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

function handleGet() {
    global $pdo;
    
    $lead_id = $_GET['lead_id'] ?? null;
    $user_id = $_GET['user_id'] ?? null;
    
    if (!$lead_id || !$user_id) {
        echo json_encode(['success' => false, 'message' => 'Lead ID and User ID are required']);
        return;
    }
    
    $stmt = $pdo->prepare("
        SELECT * FROM lead_history 
        WHERE lead_id = ? AND owner_user_id = ? 
        ORDER BY created_at DESC
    ");
    $stmt->execute([$lead_id, $user_id]);
    $history = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode(['success' => true, 'data' => $history]);
}

function handlePost() {
    global $pdo;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    $required_fields = ['lead_id', 'owner_user_id', 'title', 'description'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field])) {
            echo json_encode(['success' => false, 'message' => "Field $field is required"]);
            return;
        }
    }
    
    $stmt = $pdo->prepare("
        INSERT INTO lead_history (
            lead_id, owner_user_id, created_by, title, description, 
            priority, scheduled_at, is_recurring, is_archived, result_notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $result = $stmt->execute([
        $input['lead_id'],
        $input['owner_user_id'],
        $input['created_by'] ?? $input['owner_user_id'],
        $input['title'],
        $input['description'],
        $input['priority'] ?? 'normal',
        $input['scheduled_at'] ?? date('Y-m-d H:i:s'),
        $input['is_recurring'] ?? 0,
        $input['is_archived'] ?? 0,
        $input['result_notes'] ?? null
    ]);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'History entry created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to create history entry']);
    }
}

function handlePut() {
    global $pdo;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['id'])) {
        echo json_encode(['success' => false, 'message' => 'ID is required']);
        return;
    }
    
    $fields = [];
    $values = [];
    
    $allowed_fields = ['title', 'description', 'priority', 'scheduled_at', 'result_notes', 'is_archived'];
    
    foreach ($allowed_fields as $field) {
        if (isset($input[$field])) {
            $fields[] = "$field = ?";
            $values[] = $input[$field];
        }
    }
    
    if (empty($fields)) {
        echo json_encode(['success' => false, 'message' => 'No fields to update']);
        return;
    }
    
    $values[] = $input['id'];
    
    $stmt = $pdo->prepare("
        UPDATE lead_history 
        SET " . implode(', ', $fields) . ", updated_at = CURRENT_TIMESTAMP 
        WHERE id = ?
    ");
    
    $result = $stmt->execute($values);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'History entry updated successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to update history entry']);
    }
}

function handleDelete() {
    $id = $_GET['id'] ?? null;
    
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID is required']);
        return;
    }
    
    global $pdo;
    
    $stmt = $pdo->prepare("DELETE FROM lead_history WHERE id = ?");
    $result = $stmt->execute([$id]);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'History entry deleted successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to delete history entry']);
    }
}
?>