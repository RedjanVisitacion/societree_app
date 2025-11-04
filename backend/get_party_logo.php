<?php
require_once __DIR__ . '/config.php';

$mysqli = db_connect();
if (function_exists('mysqli_report')) { @mysqli_report(MYSQLI_REPORT_OFF); }

$party = isset($_GET['name']) ? trim($_GET['name']) : '';
if ($party === '') {
  http_response_code(400);
  header('Content-Type: application/json');
  echo json_encode(['success' => false, 'message' => 'Missing name']);
  exit();
}
// Helpers
function column_exists_local(mysqli $mysqli, string $table, string $column): bool {
  $table_esc = $mysqli->real_escape_string($table);
  $column_esc = $mysqli->real_escape_string($column);
  $db = null;
  if ($resDb = @$mysqli->query('SELECT DATABASE() AS db')) {
    if ($row = $resDb->fetch_assoc()) { $db = $row['db'] ?? null; }
    $resDb->close();
  }
  if (!$db) { return false; }
  $db_esc = $mysqli->real_escape_string($db);
  $sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='{$db_esc}' AND TABLE_NAME='{$table_esc}' AND COLUMN_NAME='{$column_esc}' LIMIT 1";
  if ($res = @$mysqli->query($sql)) { $exists = $res->num_rows > 0; $res->close(); return $exists; }
  return false;
}

// 1) Prefer most recent non-empty URL
if ($stmt = $mysqli->prepare("SELECT party_logo_url FROM candidates_registration WHERE party_name = ? AND party_logo_url IS NOT NULL AND party_logo_url <> '' ORDER BY id DESC LIMIT 1")) {
  $stmt->bind_param('s', $party);
  $stmt->execute();
  $stmt->store_result();
  if ($stmt->num_rows > 0) {
    $stmt->bind_result($url);
    $stmt->fetch();
    $stmt->close();
    header('Cache-Control: public, max-age=3600');
    header('Location: ' . $url, true, 302);
    exit();
  }
  $stmt->close();
}

// 2) Otherwise try most recent blob (if columns exist)
$has_blob = column_exists_local($mysqli, 'candidates_registration', 'party_logo_blob');
$has_mime = column_exists_local($mysqli, 'candidates_registration', 'party_logo_mime');
if ($has_blob) {
  $select = 'party_logo_blob';
  $select .= $has_mime ? ', party_logo_mime' : ', NULL AS party_logo_mime';
  $sql = "SELECT $select FROM candidates_registration WHERE party_name = ? AND party_logo_blob IS NOT NULL ORDER BY id DESC LIMIT 1";
  if ($stmt = $mysqli->prepare($sql)) {
    $stmt->bind_param('s', $party);
    $stmt->execute();
    $stmt->store_result();
    if ($stmt->num_rows > 0) {
      $stmt->bind_result($blob, $mime);
      $stmt->fetch();
      $stmt->close();
      if (!$mime) { $mime = 'application/octet-stream'; }
      header('Content-Type: ' . $mime);
      header('Cache-Control: public, max-age=3600');
      echo $blob;
      exit();
    }
    $stmt->close();
  }
}

// 3) Fallback to filesystem uploads/party_logos/{party}.{ext}
$logosDir = __DIR__ . '/uploads/party_logos';
$exts = ['jpg','jpeg','png','webp'];
$safe = strtolower(preg_replace('/[^a-zA-Z0-9_\-]+/', '_', trim($party)));
foreach ($exts as $ext) {
  $p = $logosDir . '/' . $safe . '.' . $ext;
  if (is_file($p)) {
    $mime = $ext === 'png' ? 'image/png' : ($ext === 'webp' ? 'image/webp' : 'image/jpeg');
    header('Content-Type: ' . $mime);
    header('Cache-Control: public, max-age=3600');
    readfile($p);
    exit();
  }
}

http_response_code(404);
header('Content-Type: application/json');
echo json_encode(['success' => false, 'message' => 'Not found']);
