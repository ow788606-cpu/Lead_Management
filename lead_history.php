<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        handleGet($pdo);
        break;
    case 'POST':
        handlePost($pdo);
        break;
    case 'PUT':
        handlePut($pdo);
        break;
    case 'DELETE':
        handleDelete($pdo);
        break;
    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
        break;
}

function handleGet($pdo) {
    $leadId = $_GET['lead_id'] ?? null;
    $userId = $_GET['user_id'] ?? null;
    $type = $_GET['type'] ?? null;

    if (!$leadId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Lead ID is required']);
        return;
    }

    try {
        $sql = "SELECT lh.*, u.username as user_name 
                FROM lead_history lh 
                LEFT JOIN users u ON lh.user_id = u.id 
                WHERE lh.lead_id = :lead_id";
        
        $params = ['lead_id' => $leadId];
        
        if ($type) {
            $sql .= " AND lh.type = :type";
            $params['type'] = $type;
        }
        
        if ($userId) {
            $sql .= " AND lh.user_id = :user_id";
            $params['user_id'] = $userId;
        }
        
        $sql .= " ORDER BY lh.created_at DESC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $history = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(['success' => true, 'data' => $history]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function handlePost($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        return;
    }

    $leadId = $input['lead_id'] ?? null;
    $content = $input['content'] ?? null;
    $userId = $input['user_id'] ?? null;
    $type = $input['type'] ?? 'note';

    if (!$leadId || !$content || !$userId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Lead ID, content, and user ID are required']);
        return;
    }

    try {
        $sql = "INSERT INTO lead_history (lead_id, user_id, type, content, description, created_at) 
                VALUES (:lead_id, :user_id, :type, :content, :description, NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            'lead_id' => $leadId,
            'user_id' => $userId,
            'type' => $type,
            'content' => $content,
            'description' => $content // Use content as description for notes
        ]);

        $historyId = $pdo->lastInsertId();

        echo json_encode([
            'success' => true, 
            'message' => 'History entry created successfully',
            'id' => $historyId
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function handlePut($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        return;
    }

    $id = $input['id'] ?? null;
    $content = $input['content'] ?? null;

    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'History ID is required']);
        return;
    }

    try {
        $sql = "UPDATE lead_history SET ";
        $params = ['id' => $id];
        $updates = [];

        if ($content !== null) {
            $updates[] = "content = :content";
            $updates[] = "description = :content";
            $params['content'] = $content;
        }

        if (empty($updates)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'No fields to update']);
            return;
        }

        $sql .= implode(', ', $updates) . " WHERE id = :id";

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        echo json_encode(['success' => true, 'message' => 'History entry updated successfully']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}

function handleDelete($pdo) {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        return;
    }

    $id = $input['id'] ?? null;

    if (!$id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'History ID is required']);
        return;
    }

    try {
        $sql = "DELETE FROM lead_history WHERE id = :id";
        $stmt = $pdo->prepare($sql);
        $stmt->execute(['id' => $id]);

        echo json_encode(['success' => true, 'message' => 'History entry deleted successfully']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    }
}
?>