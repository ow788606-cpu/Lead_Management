<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            $lead_id = $_GET['lead_id'] ?? null;
            $user_id = $_GET['user_id'] ?? null;
            
            if (!$lead_id || !$user_id) {
                throw new Exception('Lead ID and User ID are required');
            }
            
            $stmt = $pdo->prepare("SELECT * FROM notes WHERE lead_id = ? AND user_id = ? ORDER BY created_at DESC");
            $stmt->execute([$lead_id, $user_id]);
            $notes = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode(['success' => true, 'data' => $notes]);
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            
            $stmt = $pdo->prepare("INSERT INTO notes (lead_id, user_id, content, created_at) VALUES (?, ?, ?, NOW())");
            $stmt->execute([
                $input['lead_id'],
                $input['user_id'],
                $input['content']
            ]);
            
            echo json_encode(['success' => true, 'id' => $pdo->lastInsertId()]);
            break;
            
        default:
            throw new Exception('Method not allowed');
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>