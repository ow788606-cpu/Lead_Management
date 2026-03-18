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
                $stmt = $pdo->prepare("
                    SELECT la.*, u.userName as user_name 
                    FROM lead_activities la 
                    LEFT JOIN users u ON la.user_id = u.user_Id 
                    WHERE la.lead_id = ? 
                    ORDER BY la.created_at DESC
                ");
                $stmt->execute([$lead_id]);
                $activities = $stmt->fetchAll();
                
                // Debug logging
                error_log("Lead Activities Query for lead_id: $lead_id");
                error_log("Lead Activities Results: " . count($activities) . " records");
                
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
            
            // Handle scheduled_at field if provided
            $scheduled_at = isset($input['scheduled_at']) ? $input['scheduled_at'] : null;
            
            if ($scheduled_at) {
                $stmt = $pdo->prepare("INSERT INTO lead_activities (lead_id, activity_type, description, user_id, scheduled_at, created_at) VALUES (?, ?, ?, ?, ?, NOW())");
                $result = $stmt->execute([
                    $input['lead_id'],
                    $input['activity_type'],
                    $input['description'],
                    $input['user_id'] ?? 1,
                    $scheduled_at
                ]);
            } else {
                $stmt = $pdo->prepare("INSERT INTO lead_activities (lead_id, activity_type, description, user_id, created_at) VALUES (?, ?, ?, ?, NOW())");
                $result = $stmt->execute([
                    $input['lead_id'],
                    $input['activity_type'],
                    $input['description'],
                    $input['user_id'] ?? 1
                ]);
            }
            
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