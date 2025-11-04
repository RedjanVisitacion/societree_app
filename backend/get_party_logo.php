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

// 1) Try DB blob first
$stmt = $mysqli->prepare("SELECT party_logo_blob, party_logo_mime FROM candidates_registration WHERE party_name = ? AND party_logo_blob IS NOT NULL ORDER BY id DESC LIMIT 1");
if ($stmt) {
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

// 2) Fallback to filesystem uploads/party_logos/{party}.{ext}
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
