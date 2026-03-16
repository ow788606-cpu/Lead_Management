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
    global $conn;
    
    $lead_id = $_GET['lead_id'] ?? null;
    $user_id = $_GET['user_id'] ?? null;
    
    if (!$lead_id || !$user_id) {
        echo json_encode(['success' => false, 'message' => 'Lead ID and User ID are required']);
        return;
    }
    
    $stmt = $conn->prepare("
        SELECT * FROM notes 
        WHERE lead_id = ? AND user_id = ? 
        ORDER BY created_at DESC
    ");
    $stmt->bind_param("ii", $lead_id, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $notes = $result->fetch_all(MYSQLI_ASSOC);
    
    echo json_encode(['success' => true, 'data' => $notes]);
}

function handlePost() {
    global $conn;
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    $required_fields = ['lead_id', 'user_id', 'content'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field])) {
            echo json_encode(['success' => false, 'message' => "Field $field is required"]);
            return;
        }
    }
    
    $stmt = $conn->prepare("
        INSERT INTO notes (lead_id, user_id, content) 
        VALUES (?, ?, ?)
    ");
    
    $stmt->bind_param("iis", 
        $input['lead_id'],
        $input['user_id'],
        $input['content']
    );
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Note created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to create note']);
    }
}
?>