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
                $lead_id = (int)$_GET['lead_id']; // Ensure integer conversion
                $stmt = $pdo->prepare("
                    SELECT lt.*, u.userName as user_name 
                    FROM lead_tasks lt 
                    LEFT JOIN users u ON lt.user_id = u.user_Id 
                    WHERE lt.lead_id = ? 
                    ORDER BY lt.created_at DESC
                ");
                $stmt->execute([$lead_id]);
                $tasks = $stmt->fetchAll();
                
                // Debug logging
                error_log("Lead Tasks Query for lead_id: $lead_id");
                error_log("Lead Tasks Results: " . count($tasks) . " records");
                
                echo json_encode([
                    'success' => true,
                    'data' => $tasks
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
            
            if (!isset($input['lead_id']) || !isset($input['title'])) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Missing required fields'
                ]);
                break;
            }
            
            $stmt = $pdo->prepare("INSERT INTO lead_tasks (lead_id, title, description, priority, due_date, user_id, is_completed, created_at) VALUES (?, ?, ?, ?, ?, ?, 0, NOW())");
            $result = $stmt->execute([
                $input['lead_id'],
                $input['title'],
                $input['description'] ?? '',
                $input['priority'] ?? 'Medium',
                $input['due_date'] ?? null,
                $input['user_id'] ?? 1
            ]);
            
            if ($result) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Task saved successfully',
                    'id' => $pdo->lastInsertId()
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to save task'
                ]);
            }
            break;
            
        case 'PUT':
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['id'])) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Task ID is required'
                ]);
                break;
            }
            
            $updateFields = [];
            $params = [];
            
            if (isset($input['is_completed'])) {
                $updateFields[] = 'is_completed = ?';
                $params[] = $input['is_completed'] ? 1 : 0;
            }
            
            if (isset($input['title'])) {
                $updateFields[] = 'title = ?';
                $params[] = $input['title'];
            }
            
            if (isset($input['description'])) {
                $updateFields[] = 'description = ?';
                $params[] = $input['description'];
            }
            
            if (isset($input['priority'])) {
                $updateFields[] = 'priority = ?';
                $params[] = $input['priority'];
            }
            
            if (isset($input['due_date'])) {
                $updateFields[] = 'due_date = ?';
                $params[] = $input['due_date'];
            }
            
            if (empty($updateFields)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'No fields to update'
                ]);
                break;
            }
            
            $params[] = $input['id'];
            $sql = "UPDATE lead_tasks SET " . implode(', ', $updateFields) . " WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $result = $stmt->execute($params);
            
            if ($result) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Task updated successfully'
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Failed to update task'
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