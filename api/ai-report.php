<?php

declare(strict_types=1);

error_reporting(0);
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

$con = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($con->connect_errno) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
    exit;
}
$con->set_charset(DB_CHARSET);

if (empty($_SESSION['user_id'])) {
    ob_end_clean();
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized. Please log in.']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$payload  = json_decode(file_get_contents('php://input'), true);
$question = isset($payload['question']) ? trim((string)$payload['question']) : '';

if ($question === '' || strlen($question) > 500) {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Question is required (max 500 chars).']);
    exit;
}

$userId   = (int)$_SESSION['user_id'];
$userType = (string)($_SESSION['user_type'] ?? 'business');

$ownerId = ($userType === 'employee' && !empty($_SESSION['company_owner_user_id']))
    ? (int)$_SESSION['company_owner_user_id']
    : $userId;

$_q = strtolower(trim($question));

$_greetings = [
    '/^(hi|hey|hello|howdy|hiya|yo|sup|what\'?s up|wassup)[!\s?]*$/i',
    '/^good\s+(morning|afternoon|evening|night|day)[!\s?]*$/i',
    '/^how are you[?!.\s]*$/i',
    '/^(thanks|thank you|thx|ty)[!.\s]*$/i',
    '/^(ok|okay|cool|great|nice|awesome|perfect|got it|sure)[!.\s]*$/i',
    '/^(bye|goodbye|see you|cya|later)[!.\s]*$/i',
];
$_isGreeting = false;
foreach ($_greetings as $_pat) {
    if (preg_match($_pat, $_q)) { $_isGreeting = true; break; }
}

if ($_isGreeting) {
    $userName = $_SESSION['full_name'] ?? 'there';
    $firstName = explode(' ', trim($userName))[0];
    $greetingReplies = [
        "Hey {$firstName}! 👋 I'm your CRM assistant. Ask me about your leads, tasks, or contacts.",
        "Hello {$firstName}! I'm ready to help you explore your CRM data. Try asking about leads or tasks!",
        "Hi {$firstName}! 😊 What would you like to know about your leads, tasks, or contacts today?",
    ];
    $reply = $greetingReplies[array_rand($greetingReplies)];
    ob_end_clean();
    echo json_encode([
        'success'      => true,
        'answer'       => $reply,
        'intent'       => ['table' => 'none', 'intent' => 'greeting'],
        'data'         => [],
        'count'        => 0,
        'redirect_url' => null,
        'question'     => $question,
    ]);
    exit;
}

if (preg_match('/\b(overview|summary|my\s+day|my\s+schedule|today[\'s]*\s*(overview|summary|schedule|plan|report)|daily\s*(brief|summary|report)|what.*on\s+today|schedule)\b/i', $_q)) {
    $today    = date('Y-m-d');
    $userType = (string)($_SESSION['user_type'] ?? 'business');
    $ownerId  = ($userType === 'employee' && !empty($_SESSION['company_owner_user_id']))
        ? (int)$_SESSION['company_owner_user_id'] : $userId;

    $lScope = $userType === 'business' ? "l.owner_user_id = {$ownerId}" : "l.assigned_to = {$userId}";
    $tScope = $userType === 'business' ? "t.owner_user_id = {$ownerId}" : "t.assigned_to = {$userId}";

    $s = $con->prepare("SELECT COUNT(*) AS n FROM leads l WHERE {$lScope} AND l.status=1 AND l.deleted_at IS NULL AND (DATE(l.next_followup_at)=? OR DATE(l.updated_at)=?)");
    $s->bind_param('ss', $today, $today); $s->execute();
    $cAppts = (int)$s->get_result()->fetch_assoc()['n']; $s->close();

    $s = $con->prepare("SELECT COUNT(*) AS n FROM leads l WHERE {$lScope} AND l.status IN (2,5,6,7,10,11,12) AND l.deleted_at IS NULL AND (DATE(l.next_followup_at)=? OR DATE(l.updated_at)=?)");
    $s->bind_param('ss', $today, $today); $s->execute();
    $cFollowups = (int)$s->get_result()->fetch_assoc()['n']; $s->close();

    $s = $con->prepare("SELECT COUNT(*) AS n FROM tasks t WHERE {$tScope} AND t.completed_at IS NULL AND t.deleted_at IS NULL AND DATE(t.due_at)=?");
    $s->bind_param('s', $today); $s->execute();
    $cTasks = (int)$s->get_result()->fetch_assoc()['n']; $s->close();

    $s = $con->prepare("SELECT COUNT(*) AS n FROM leads l WHERE {$lScope} AND l.status=0 AND l.deleted_at IS NULL AND DATE(l.created_at)=?");
    $s->bind_param('s', $today); $s->execute();
    $cFresh = (int)$s->get_result()->fetch_assoc()['n']; $s->close();

    $total = $cAppts + $cFollowups + $cTasks + $cFresh;
    $userName = $_SESSION['full_name'] ?? 'there';
    $firstName = explode(' ', trim($userName))[0];

    if ($total === 0) {
        $funnyMsgs = [
            "🎉 You're crushing it, {$firstName}! No appointments, follow-ups, or tasks today. But hey, the pipeline won't fill itself. Go get some leads! 💪",
            "☀️ Clear skies today, {$firstName}! Nothing on the schedule. A great day to chase new leads and close some deals!",
            "🏖️ All clear, {$firstName}! Your to-do list is on vacation today. Why not add some fresh leads and make tomorrow count?",
        ];
        $answer = $funnyMsgs[array_rand($funnyMsgs)];
    } else {
        $answer = "Here's your overview for today, {$firstName}! 📋";
    }

    ob_end_clean();
    echo json_encode([
        'success'      => true,
        'answer'       => $answer,
        'intent'       => ['table' => 'none', 'intent' => 'overview'],
        'data'         => [],
        'count'        => $total,
        'redirect_url' => null,
        'question'     => $question,
        'overview'     => [
            'appointments' => $cAppts,
            'followups'    => $cFollowups,
            'tasks'        => $cTasks,
            'fresh'        => $cFresh,
            'empty'        => $total === 0,
        ],
    ]);
    exit;
}

$_crmKeywords = '/\b(lead|leads|task|tasks|contact|contacts|user|users|appointment|appt|follow.?up|won|lost|fresh|new|active|pending|completed|overdue|priority|assign|today|week|month|count|how many|show|list|find|search|total|overview|summary|schedule|my\s+day)\b/i';
if (!preg_match($_crmKeywords, $_q)) {
    ob_end_clean();
    echo json_encode([
        'success'      => true,
        'answer'       => "I can only help with your CRM data. Use the suggestions on the left to explore your leads, tasks, and contacts. 👈",
        'intent'       => ['table' => 'none', 'intent' => 'out_of_scope'],
        'data'         => [],
        'count'        => 0,
        'redirect_url' => null,
        'question'     => $question,
    ]);
    exit;
}

$intent = ai_parse_with_rules($question);
$intent['parser'] = 'php_rules';

if (in_array($intent['table'] ?? '', ['leads', 'tasks'], true)) {
    $intent['intent'] = 'count';
}

$queryResult = ai_build_query($intent, $userId, $ownerId, $userType);

if ($queryResult['sql'] === null) {
    ob_end_clean();
    echo json_encode([
        'success' => false,
        'message' => 'Could not understand that question. Try: "How many active leads?", "Show pending tasks", "Leads assigned to Rahul".',
    ]);
    exit;
}

$stmt = $con->prepare($queryResult['sql']);
if ($stmt === false) {
    ob_end_clean();
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Query error: ' . $con->error]);
    exit;
}

if (!empty($queryResult['params'])) {
    $stmt->bind_param($queryResult['types'], ...$queryResult['params']);
}

$stmt->execute();
$result = $stmt->get_result();
$rows   = [];
while ($row = $result->fetch_assoc()) {
    $rows[] = $row;
}
$stmt->close();

$answer      = ai_format_answer($intent, $rows);
$redirectUrl = null;

if (($intent['table'] ?? '') === 'leads') {
    $redirectUrl = ai_build_leads_redirect_url($intent, $con, $ownerId);
} elseif (($intent['table'] ?? '') === 'tasks') {
    $redirectUrl = ai_build_tasks_redirect_url($intent, $con, $ownerId);
}

ob_end_clean();

echo json_encode([
    'success'      => true,
    'answer'       => $answer,
    'intent'       => $intent,
    'data'         => !in_array($intent['table'] ?? '', ['leads','tasks'], true) && ($intent['intent'] ?? '') === 'list' ? $rows : [],
    'count'        => (int)($rows[0]['total'] ?? count($rows)),
    'redirect_url' => $redirectUrl,
    'question'     => $question,
]);


function ai_call_python_server(string $question): ?array
{
    if (!function_exists('curl_init')) {
        return null;
    }

    $ch = curl_init('http://127.0.0.1:5000/query');
    if ($ch === false) {
        return null;
    }

    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode(['question' => $question]),
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT        => 12,
        CURLOPT_CONNECTTIMEOUT => 3,
    ]);

    $res      = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200 || $res === false) {
        return null;
    }

    $parsed = json_decode($res, true);
    if (isset($parsed['intent'], $parsed['table'], $parsed['filters'])) {
        return $parsed;
    }

    return null;
}


function ai_parse_with_rules(string $question): array
{
    $q = strtolower($question);

    $intent = 'list';
    foreach (['how many', 'count', 'total', 'number of'] as $kw) {
        if (str_contains($q, $kw)) { $intent = 'count'; break; }
    }

    $table = 'leads';
    if (preg_match('/\b(task|tasks|todo|to-do|reminder|reminders)\b/', $q)) {
        $table = 'tasks';
    } elseif (preg_match('/\b(contact|contacts|client|clients|person|people)\b/', $q)) {
        $table = 'contacts';
    } elseif (preg_match('/\b(user|users|employee|employees|staff|team|member|members)\b/', $q)) {
        $table = 'users';
    }

    $filters = [
        'status'           => null,
        'assigned_to_name' => null,
        'date_range'       => null,
        'priority'         => null,
        'overdue'          => false,
        'search_keyword'   => null,
    ];

    if (str_contains($q, 'today')) {
        $filters['date_range'] = 'today';
    } elseif (str_contains($q, 'this week')) {
        $filters['date_range'] = 'this_week';
    } elseif (str_contains($q, 'this month')) {
        $filters['date_range'] = 'this_month';
    }

    if ($table === 'leads') {
        if (preg_match('/\b(fresh|new lead|new leads)\b/', $q)) {
            $filters['status'] = 'fresh';
        } elseif (preg_match('/appoint|\bappts?\b/', $q)) {
            $filters['status'] = 'appointment';
        } elseif (preg_match('/\bfollow.?up\b/', $q)) {
            $filters['status'] = 'followup';
        } elseif (preg_match('/\b(won|closed|converted|win)\b/', $q)) {
            $filters['status'] = 'won';
        } elseif (preg_match('/\b(lost|dead|rejected|lose)\b/', $q)) {
            $filters['status'] = 'lost';
        } elseif (preg_match('/\b(active|open|ongoing)\b/', $q)) {
            $filters['status'] = 'active';
        }

        if (str_contains($q, 'overdue')) {
            $filters['overdue'] = true;
        }
    }

    if ($table === 'tasks') {
        if (preg_match('/\b(pending|incomplete|open|remaining)\b/', $q)) {
            $filters['status'] = 'pending';
        } elseif (preg_match('/\b(completed|done|finished)\b/', $q)) {
            $filters['status'] = 'completed';
        }

        if (preg_match('/\b(overdue|late|missed)\b/', $q)) {
            $filters['overdue'] = true;
            if ($filters['status'] === null) {
                $filters['status'] = 'pending';
            }
        }

        if (preg_match('/\b(critical|urgent)\b/', $q)) {
            $filters['priority'] = 'critical';
        } elseif (preg_match('/\bhigh\b/', $q)) {
            $filters['priority'] = 'high';
        } elseif (preg_match('/\blow\b/', $q)) {
            $filters['priority'] = 'low';
        } elseif (preg_match('/\b(normal|medium)\b/', $q)) {
            $filters['priority'] = 'normal';
        }
    }

    $assigneeName = '';
    if (preg_match('/\bassigned\s+to\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)/i', $question, $m)) {
        $assigneeName = trim($m[1]);
    }
    if ($assigneeName !== '') {
        $stop = ['me', 'my', 'all', 'the', 'a', 'an', 'any', 'some'];
        if (!in_array(strtolower($assigneeName), $stop, true)) {
            $filters['assigned_to_name'] = $assigneeName;
        }
    }

    $keyword = '';

    if (preg_match("/([A-Za-z]+(?:\s+[A-Za-z]+)?)'s\s+(?:lead|leads|contact|task|tasks)/i", $question, $m)) {
        $keyword = trim($m[1]);
    }

    if ($keyword === '' && preg_match('/\b(\+?[\d][\d\s\-\(\)]{5,}[\d])\b/', $question, $pm)) {
        $keyword = preg_replace('/[\s\-\(\)]/', '', $pm[1]);
    }

    if ($keyword === '' && preg_match(
        '/\b(?:find|search|look\s?up|show)\s+(?:leads?\s+(?:for|of|by)\s+|contact\s+)?([A-Za-z][\w\s]{1,25}?)(?:\s+lead|\s+contact|$|\?)/i',
        $question, $m
    )) {
        $candidate = trim($m[1]);
        $skip = ['me', 'my', 'all', 'active', 'pending', 'today', 'this'];
        if (!in_array(strtolower($candidate), $skip, true)) {
            $keyword = $candidate;
        }
    }

    if ($keyword !== '') {
        $stop = ['me', 'my', 'all', 'the', 'a', 'an'];
        if (!in_array(strtolower($keyword), $stop, true)) {
            $filters['search_keyword'] = $keyword;
        }
    }

    return [
        'intent'  => $intent,
        'table'   => $table,
        'filters' => $filters,
    ];
}


function ai_build_query(array $intent, int $userId, int $ownerId, string $userType): array
{
    $table   = $intent['table']   ?? 'leads';
    $isCount = ($intent['intent'] ?? 'list') === 'count';
    $filters = $intent['filters'] ?? [];

    $params = [];
    $types  = '';
    $where  = [];
    $sql    = null;

    switch ($table) {

        case 'leads':
            $select = $isCount
                ? "SELECT COUNT(*) AS total"
                : "SELECT l.id,
                          c.name            AS contact_name,
                          c.email,
                          c.contact_number  AS phone,
                          st.name           AS status_name,
                          l.status,
                          l.next_followup_at,
                          l.created_at,
                          ua.full_name      AS assigned_to_name";

            $from = "FROM leads l
                     LEFT JOIN contacts c   ON c.id = l.contact_id
                     LEFT JOIN status   st  ON st.id = l.status
                     LEFT JOIN users    ua  ON ua.user_Id = l.assigned_to";

            $where[] = "l.deleted_at IS NULL";

            if ($userType === 'employee') {
                $where[]  = "l.assigned_to = ?";
                $params[] = $userId; $types .= 'i';
            } else {
                $where[]  = "l.owner_user_id = ?";
                $params[] = $ownerId; $types .= 'i';
            }

            $status = $filters['status'] ?? null;
            if ($status !== null) {
                switch ($status) {
                    case 'fresh':       $where[] = "l.status = 0"; break;
                    case 'appointment': $where[] = "l.status = 1"; break;
                    case 'followup':    $where[] = "l.status IN (2,5,6,7,10,11)"; break;
                    case 'won':         $where[] = "l.status = 4"; break;
                    case 'lost':        $where[] = "l.status IN (3,8,9)"; break;
                    case 'active':      $where[] = "l.status IN (0,1,2,5,6,7,10,11)"; break;
                }
            }

            if (!empty($filters['overdue'])) {
                $where[] = "l.next_followup_at IS NOT NULL AND l.next_followup_at < NOW()";
                $where[] = "l.status IN (0,1,2,5,6,7,10,11)";
            }

            $dateRange  = $filters['date_range'] ?? null;
            $dateColumn = ($status === 'appointment') ? "l.next_followup_at" : "l.created_at";
            if ($dateRange === 'today') {
                $where[] = "DATE($dateColumn) = CURDATE()";
            } elseif ($dateRange === 'this_week') {
                $where[] = "YEARWEEK($dateColumn, 1) = YEARWEEK(CURDATE(), 1)";
            } elseif ($dateRange === 'this_month') {
                $where[] = "YEAR($dateColumn) = YEAR(CURDATE()) AND MONTH($dateColumn) = MONTH(CURDATE())";
            }

            if (!empty($filters['assigned_to_name'])) {
                $where[]  = "ua.full_name LIKE ?";
                $params[] = '%' . $filters['assigned_to_name'] . '%';
                $types   .= 's';
            }

            if (!empty($filters['search_keyword'])) {
                $like     = '%' . $filters['search_keyword'] . '%';
                $where[]  = "(c.name LIKE ? OR c.contact_number LIKE ? OR c.email LIKE ?)";
                $params[] = $like; $params[] = $like; $params[] = $like;
                $types   .= 'sss';
            }

            $whereStr = 'WHERE ' . implode(' AND ', array_unique($where));
            $orderBy  = $isCount ? '' : 'ORDER BY l.created_at DESC LIMIT 50';
            $sql      = "$select $from $whereStr $orderBy";
            break;


        case 'tasks':
            $select = $isCount
                ? "SELECT COUNT(*) AS total"
                : "SELECT t.id,
                          t.title,
                          t.description,
                          t.status,
                          t.priority,
                          t.due_at,
                          t.created_at,
                          u.full_name   AS assigned_to_name,
                          c.name        AS contact_name";

            $from = "FROM tasks t
                     LEFT JOIN users    u  ON u.user_Id = t.assigned_to
                     LEFT JOIN contacts c  ON c.id = t.contact_id";

            $where[] = "t.deleted_at IS NULL";

            if ($userType === 'employee') {
                $where[]  = "(t.assigned_to = ? OR t.created_by = ?)";
                $params[] = $userId; $params[] = $userId; $types .= 'ii';
            } else {
                $where[]  = "t.owner_user_id = ?";
                $params[] = $ownerId; $types .= 'i';
            }

            $taskStatus = $filters['status'] ?? null;
            if ($taskStatus === 'pending') {
                $where[] = "t.status = 'pending'";
            } elseif ($taskStatus === 'completed') {
                $where[] = "t.status = 'completed'";
            }

            if (!empty($filters['priority'])) {
                $where[]  = "t.priority = ?";
                $params[] = $filters['priority']; $types .= 's';
            }

            if (!empty($filters['overdue'])) {
                $where[] = "t.due_at IS NOT NULL AND t.due_at < NOW()";
                $where[] = "t.status = 'pending'";
            }

            $dateRange = $filters['date_range'] ?? null;
            if ($dateRange === 'today') {
                $where[] = "DATE(t.due_at) = CURDATE()";
            } elseif ($dateRange === 'this_week') {
                $where[] = "YEARWEEK(t.due_at, 1) = YEARWEEK(CURDATE(), 1)";
            } elseif ($dateRange === 'this_month') {
                $where[] = "YEAR(t.due_at) = YEAR(CURDATE()) AND MONTH(t.due_at) = MONTH(CURDATE())";
            }

            if (!empty($filters['assigned_to_name'])) {
                $where[]  = "u.full_name LIKE ?";
                $params[] = '%' . $filters['assigned_to_name'] . '%';
                $types   .= 's';
            }

            $whereStr = 'WHERE ' . implode(' AND ', array_unique($where));
            $orderBy  = $isCount ? '' : 'ORDER BY t.due_at ASC, t.created_at DESC LIMIT 50';
            $sql      = "$select $from $whereStr $orderBy";
            break;


        case 'contacts':
            $select = $isCount
                ? "SELECT COUNT(*) AS total"
                : "SELECT c.id, c.name, c.email, c.contact_number AS phone,
                          c.status, c.created_at";

            $from = "FROM contacts c";

            $where[]  = "c.deleted_at IS NULL";
            $where[]  = "c.owner_user_id = ?";
            $params[] = $ownerId; $types .= 'i';

            $dateRange = $filters['date_range'] ?? null;
            if ($dateRange === 'today') {
                $where[] = "DATE(c.created_at) = CURDATE()";
            } elseif ($dateRange === 'this_week') {
                $where[] = "YEARWEEK(c.created_at, 1) = YEARWEEK(CURDATE(), 1)";
            } elseif ($dateRange === 'this_month') {
                $where[] = "YEAR(c.created_at) = YEAR(CURDATE()) AND MONTH(c.created_at) = MONTH(CURDATE())";
            }

            $whereStr = 'WHERE ' . implode(' AND ', array_unique($where));
            $orderBy  = $isCount ? '' : 'ORDER BY c.created_at DESC LIMIT 50';
            $sql      = "$select $from $whereStr $orderBy";
            break;


        case 'users':
            $select = $isCount
                ? "SELECT COUNT(*) AS total"
                : "SELECT u.user_Id AS id, u.full_name, u.email,
                          u.user_type, u.current_status, u.created_at";

            $from = "FROM users u";

            $where[]  = "u.deleted_at IS NULL";
            $where[]  = "u.company_owner_user_id = ?";
            $params[] = $ownerId; $types .= 'i';

            $whereStr = 'WHERE ' . implode(' AND ', array_unique($where));
            $orderBy  = $isCount ? '' : 'ORDER BY u.full_name ASC LIMIT 50';
            $sql      = "$select $from $whereStr $orderBy";
            break;

        default:
            return ['sql' => null, 'params' => [], 'types' => ''];
    }

    return ['sql' => $sql, 'params' => $params, 'types' => $types];
}


function ai_format_answer(array $intent, array $rows): string
{
    $table   = $intent['table']   ?? 'leads';
    $isCount = ($intent['intent'] ?? 'list') === 'count';
    $filters = $intent['filters'] ?? [];

    $statusLabels = [
        'fresh'       => 'fresh',
        'appointment' => 'appointment scheduled',
        'followup'    => 'in follow-up',
        'won'         => 'won',
        'lost'        => 'lost',
        'active'      => 'active',
        'pending'     => 'pending',
        'completed'   => 'completed',
    ];

    $statusLabel   = $statusLabels[$filters['status'] ?? ''] ?? '';
    $overdueLabel  = !empty($filters['overdue'])           ? 'overdue '   : '';
    $assignLabel   = !empty($filters['assigned_to_name'])  ? ' assigned to ' . $filters['assigned_to_name'] : '';
    $keywordLabel  = !empty($filters['search_keyword'])    ? ' matching "' . $filters['search_keyword'] . '"' : '';

    $priorityLabel = '';
    if ($table === 'tasks' && !empty($filters['priority'])) {
        $priorityLabel = $filters['priority'] . ' priority ';
    }

    $dateLabels = [
        'today'      => ' today',
        'this_week'  => ' this week',
        'this_month' => ' this month',
    ];
    $dateLabel = $dateLabels[$filters['date_range'] ?? ''] ?? '';

    $noun = $overdueLabel . $priorityLabel . ($statusLabel !== '' ? "$statusLabel " : '') . $table;

    if ($isCount) {
        $total = (int)($rows[0]['total'] ?? 0);
        $main  = "You have **{$total}** {$noun}{$dateLabel}{$assignLabel}.";
        $insight = ai_count_insight($table, $filters, $total, $dateLabel);
        return $insight !== '' ? $main . "\n\n" . $insight : $main;
    }

    $n = count($rows);

    if ($n === 0) {
        $emptyMsg = ai_empty_insight($table, $filters, $dateLabel, $assignLabel, $keywordLabel, $noun);
        return $emptyMsg;
    }

    $preview = array_slice($rows, 0, 10);
    $lines   = [];

    foreach ($preview as $row) {
        switch ($table) {
            case 'leads':
                $contact = $row['contact_name'] ?? 'Unknown';
                $status  = $row['status_name']  ?? '—';
                $followup = !empty($row['next_followup_at'])
                    ? '  _(next: ' . date('M j, Y', strtotime($row['next_followup_at'])) . ')_'
                    : '';
                $lines[] = "• **{$contact}**, {$status}{$followup}";
                break;

            case 'tasks':
                $title    = $row['title']    ?? 'Untitled';
                $priority = $row['priority'] ?? '';
                $due      = !empty($row['due_at'])
                    ? '  _(due: ' . date('M j, Y', strtotime($row['due_at'])) . ')_'
                    : '';
                $lines[] = "• **{$title}** [{$priority}]{$due}";
                break;

            case 'contacts':
                $lines[] = "• **{$row['name']}**, {$row['email']}";
                break;

            case 'users':
                $lines[] = "• **{$row['full_name']}** ({$row['email']}), {$row['user_type']}";
                break;
        }
    }

    $more   = $n > 10 ? "\n_...and " . ($n - 10) . " more._" : '';
    $header = "Here are **{$n}** {$noun}{$dateLabel}{$assignLabel}:";

    return $header . "\n\n" . implode("\n", $lines) . $more;
}


function ai_count_insight(string $table, array $filters, int $total, string $dateLabel): string
{
    $status  = $filters['status']   ?? null;
    $overdue = !empty($filters['overdue']);
    $priority = $filters['priority'] ?? null;

    if ($table === 'leads') {
        if ($overdue) {
            if ($total === 0) return "🎯 Great discipline, no overdue leads! Keep following up on time.";
            if ($total <= 3)  return "⏰ A few need attention. Overdue leads cool off fast, reach out today.";
            if ($total <= 10) return "⚠️ These leads haven't been followed up recently. The sooner you reconnect, the better your chances of converting them.";
            return "🚨 That's quite a backlog! Prioritise the most recent ones first, older overdue leads are harder to revive.";
        }
        switch ($status) {
            case 'fresh':
                if ($total === 0) return "No new leads yet{$dateLabel}. Try adding some from your contacts or import a list!";
                if ($total <= 5)  return "📥 New leads are in! Fresh leads respond best when contacted within 24 hours, strike while the iron is hot.";
                return "📥 You've got **{$total}** fresh leads waiting. Prioritise a quick intro call, early contact dramatically improves conversion rates.";
            case 'appointment':
                if ($total === 0) return "No appointments scheduled{$dateLabel}. A good time to follow up and book some slots!";
                return "📅 Stay prepared, review each lead before the meeting to personalise your pitch.";
            case 'followup':
            case null:
                if ($total === 0) return "All caught up on follow-ups! Great time to convert some to appointments.";
                if ($total > 15) return "💬 Lots of follow-ups in the queue. Consider prioritising leads with the nearest next-follow-up date.";
                return "💬 Keep the momentum going, consistent follow-ups are the key to closing deals.";
            case 'won':
                if ($total === 0) return "No won leads yet{$dateLabel}. Keep pushing, every 'no' brings you closer to a 'yes'!";
                if ($total >= 10) return "🏆 Impressive! Double down on what's working to keep those wins coming.";
                return "🎉 Nice work closing these deals! Review what worked and replicate it for your active leads.";
            case 'lost':
                if ($total === 0) return "No lost leads{$dateLabel}. You're on a great streak! 💪";
                return "📊 It happens. Consider a re-engagement sequence for recent losses, sometimes timing is everything.";
            case 'active':
                if ($total === 0) return "No active leads in the pipeline right now. Time to add some fresh prospects!";
                if ($total > 30) return "🔥 Busy pipeline! Make sure each lead has a clear next action so nothing falls through the cracks.";
                return "📈 Solid pipeline. Focus on moving each lead to the next stage, small steps compound over time.";
        }
    }

    if ($table === 'tasks') {
        if ($overdue) {
            if ($total === 0) return "✅ No overdue tasks, you're on top of things!";
            if ($total <= 3)  return "⏰ A few tasks slipped past the deadline. Tackle them now before the list grows.";
            if ($total <= 10) return "⚠️ These tasks need immediate attention. Try blocking 30 minutes to clear as many as you can.";
            return "🚨 Quite a few tasks are overdue. Consider delegating or rescheduling lower-priority ones to stay focused.";
        }
        switch ($priority) {
            case 'critical':
                if ($total === 0) return "✅ No critical tasks, things are under control!";
                return "🔴 Critical tasks demand immediate focus. Clear these before moving to anything else.";
            case 'high':
                if ($total === 0) return "✅ No high priority tasks at the moment. Great time to get ahead on normal ones.";
                return "🟠 High priority tasks are waiting. Block focused time in your calendar to knock these out.";
            case 'low':
                return $total === 0 ? "No low priority tasks right now." : "These are low priority, schedule them when you have breathing room.";
            default:
                if ($total === 0) return "✅ All clear, no tasks in this filter!";
                if ($total > 20) return "📋 That's a long list! Break it into smaller daily goals to stay motivated and productive.";
                return "📋 Stay organised, try to complete your oldest tasks first to keep the backlog from growing.";
        }
    }

    if ($table === 'contacts') {
        if ($total === 0) return "No contacts found. Add some to start building your network!";
        if ($total > 50) return "📇 You have a large contact base. Make sure each contact has an active lead or engagement plan.";
        return "📇 Your contact list is your goldmine, make sure every contact is linked to a lead or opportunity.";
    }

    if ($table === 'users') {
        if ($total === 0) return "No team members found. Invite your team to collaborate in Cloop!";
        return "👥 Tip: Assign leads to team members evenly so no one gets overwhelmed and nothing falls through.";
    }

    return '';
}


function ai_empty_insight(string $table, array $filters, string $dateLabel, string $assignLabel, string $keywordLabel, string $noun): string
{
    $status  = $filters['status']   ?? null;
    $overdue = !empty($filters['overdue']);

    if (!empty($keywordLabel)) {
        return "No {$noun} found{$keywordLabel}. Double-check the spelling or try a partial name/number.";
    }

    if ($overdue) {
        return $table === 'leads'
            ? "🎯 No overdue leads, your follow-up game is strong! Keep it up."
            : "✅ No overdue tasks. You're ahead of schedule, nice work!";
    }

    if ($table === 'leads') {
        $map = [
            'fresh'       => "No fresh leads{$dateLabel}. A great time to add new prospects or import a list!",
            'appointment' => "No appointments{$dateLabel}{$assignLabel}. Start converting your follow-ups into booked meetings!",
            'followup'    => "No follow-ups{$dateLabel}{$assignLabel}. All caught up, great pipeline hygiene! 💪",
            'won'         => "No won leads{$dateLabel}{$assignLabel}. Keep pushing, your next win could be just one call away!",
            'lost'        => "No lost leads{$dateLabel}{$assignLabel}. Excellent retention! 🎉",
            'active'      => "No active leads{$dateLabel}{$assignLabel}. Add fresh leads to keep your pipeline healthy.",
        ];
        return $map[$status ?? ''] ?? "No leads found{$dateLabel}{$assignLabel}. Try broadening your search.";
    }

    if ($table === 'tasks') {
        $map = [
            'pending'   => "✅ No pending tasks{$dateLabel}{$assignLabel}. All clear, consider getting ahead on tomorrow's work!",
            'completed' => "No completed tasks yet{$dateLabel}{$assignLabel}. Start checking things off the list!",
        ];
        return $map[$status ?? ''] ?? "No tasks found{$dateLabel}{$assignLabel}.";
    }

    if ($table === 'contacts') {
        return "No contacts found{$dateLabel}. Try adding some from your leads or import a CSV.";
    }

    return "No {$noun} found{$dateLabel}{$assignLabel}.";
}


function ai_resolve_user_id(string $name, int $ownerId, mysqli $con): ?int
{
    $stmt = $con->prepare(
        "SELECT user_Id FROM users
         WHERE (company_owner_user_id = ? OR user_Id = ?)
           AND full_name LIKE ?
           AND deleted_at IS NULL
         ORDER BY full_name ASC
         LIMIT 1"
    );
    if (!$stmt) return null;

    $like = '%' . $name . '%';
    $stmt->bind_param('iis', $ownerId, $ownerId, $like);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    return $row ? (int)$row['user_Id'] : null;
}


function ai_build_leads_redirect_url(array $intent, mysqli $con, int $ownerId): string
{
    $filters  = $intent['filters'] ?? [];
    $params   = [];

    $statusKeyToParam = [
        'fresh'       => 0,
        'appointment' => 1,
        'followup'    => 'in_progress',
        'won'         => 4,
        'lost'        => 9,
        'active'      => 'in_progress',
    ];

    if (!empty($filters['overdue'])) {
        $params['status'] = 'overdue';
    } elseif (!empty($filters['status']) && isset($statusKeyToParam[$filters['status']])) {
        $params['status'] = $statusKeyToParam[$filters['status']];
    }

    $dateRange = $filters['date_range'] ?? null;
    $isAppt    = ($filters['status'] ?? null) === 'appointment';

    if ($dateRange === 'today' && $isAppt) {
        $params['period'] = 'today';
    } elseif ($dateRange === 'today') {
        $today = date('Y-m-d');
        $params['date_from'] = $today;
        $params['date_to']   = $today;
    } elseif ($dateRange === 'this_week') {
        $params['date_from'] = date('Y-m-d', strtotime('monday this week'));
        $params['date_to']   = date('Y-m-d', strtotime('sunday this week'));
    } elseif ($dateRange === 'this_month') {
        $params['date_from'] = date('Y-m-01');
        $params['date_to']   = date('Y-m-t');
    }

    if (!empty($filters['assigned_to_name'])) {
        $uid = ai_resolve_user_id($filters['assigned_to_name'], $ownerId, $con);
        if ($uid !== null) {
            $params['assigned'] = $uid;
        }
    }

    if (!empty($filters['search_keyword'])) {
        $params['search'] = $filters['search_keyword'];
    }

    $query = $params ? '?' . http_build_query($params) : '';
    return 'leads/index.php' . $query;
}


function ai_build_tasks_redirect_url(array $intent, mysqli $con, int $ownerId): string
{
    $filters = $intent['filters'] ?? [];
    $params  = [];

    $page = ($filters['status'] ?? null) === 'completed'
        ? 'tasks/completed-tasks.php'
        : 'tasks/pending-tasks.php';

    if (!empty($filters['assigned_to_name'])) {
        $uid = ai_resolve_user_id($filters['assigned_to_name'], $ownerId, $con);
        if ($uid !== null) {
            $params['assigned_to'] = $uid;
        }
    }

    $allowedPriority = ['low', 'normal', 'high', 'critical'];
    if (!empty($filters['priority']) && in_array($filters['priority'], $allowedPriority, true)) {
        $params['priority'] = $filters['priority'];
    }

    if (($filters['date_range'] ?? '') === 'today') {
        $params['period'] = 'today';
    }

    $query = $params ? '?' . http_build_query($params) : '';
    return $page . $query;
}
