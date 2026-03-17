<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'db.php';

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['lead_id'])) {
                $lead_id = (int)$_GET['lead_id'];
                $stmt = $pdo->prepare("SELECT * FROM lead_activities WHERE lead_id = ? ORDER BY created_at DESC");
                $stmt->execute([$lead_id]);
                $activities = $stmt->fetchAll();
                
                echo json_encode([
                    'success' => true,
                    'data' => $activities
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Lead ID is required'
                ]);
            }
            break;
            
        case 'POST':
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['lead_id']) || !isset($input['activity_type']) || !isset($input['description'])) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Missing required fields'
                ]);
                break;
            }
            
            $stmt = $pdo->prepare("INSERT INTO lead_activities (lead_id, activity_type, description, user_id, created_at) VALUES (?, ?, ?, ?, NOW())");
            $result = $stmt->execute([
                $input['lead_id'],
                $input['activity_type'],
                $input['description'],
                $input['user_id'] ?? 1
            ]);
            
            if ($result) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Activity saved successfully',
                    'id' => $pdo->lastInsertId()
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to save activity'
                ]);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode([
                'success' => false,
                'message' => 'Method not allowed'
            ]);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>