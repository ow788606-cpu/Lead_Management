<?php
require_once 'api/db.php';

$dryRun = isset($_GET['dry_run']);

function loadTagMap(PDO $pdo): array {
    $map = [];
    $stmt = $pdo->query("SELECT id, name FROM tags WHERE deleted_at IS NULL");
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $id = (int)($row['id'] ?? 0);
        $name = trim((string)($row['name'] ?? ''));
        if ($id > 0 && $name !== '') {
            $map[$id] = $name;
        }
    }
    return $map;
}

function normalizeTags(string $raw, array $tagMap): string {
    $parts = array_map('trim', explode(',', $raw));
    $result = [];
    foreach ($parts as $part) {
        if ($part === '') {
            continue;
        }
        if (ctype_digit($part)) {
            $id = (int)$part;
            if (isset($tagMap[$id])) {
                $part = $tagMap[$id];
            }
        }
        if ($part !== '' && !in_array($part, $result, true)) {
            $result[] = $part;
        }
    }
    return implode(', ', $result);
}

try {
    $tagMap = loadTagMap($pdo);
    $stmt = $pdo->query("SELECT id, tags FROM leads");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $updated = 0;
    foreach ($rows as $row) {
        $leadId = (int)($row['id'] ?? 0);
        $rawTags = trim((string)($row['tags'] ?? ''));
        if ($leadId <= 0 || $rawTags === '') {
            continue;
        }

        $normalized = normalizeTags($rawTags, $tagMap);
        if ($normalized === '' || $normalized === $rawTags) {
            continue;
        }

        if (!$dryRun) {
            $update = $pdo->prepare("UPDATE leads SET tags = ?, updated_at = NOW() WHERE id = ?");
            $update->execute([$normalized, $leadId]);
        }
        $updated++;
    }

    echo $dryRun
        ? "Dry run complete. Leads to update: {$updated}\n"
        : "Migration complete. Leads updated: {$updated}\n";
} catch (Exception $e) {
    echo "Migration failed: " . $e->getMessage();
}
