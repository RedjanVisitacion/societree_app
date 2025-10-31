<?php
// Streams a candidate photo by student_id or full name.
// Priority: DB (candidates_registration.photo_blob/photo_mime). Fallback: filesystem uploads/candidates.

require_once __DIR__ . '/config.php';

$baseDir = __DIR__ . '/uploads/candidates';
$exts = ['jpg','jpeg','png','webp'];

$name = isset($_GET['name']) ? trim($_GET['name']) : '';
$studentId = isset($_GET['student_id']) ? trim($_GET['student_id']) : '';

function stream_blob($blob, $mime) {
  if (!$blob) return false;
  if (!$mime) { $mime = 'image/jpeg'; }
  header('Content-Type: ' . $mime);
  header('Cache-Control: public, max-age=86400');
  echo $blob;
  return true;
}

// 1) Try DB first
$mysqli = db_connect();

if ($studentId !== '') {
  if ($stmt = $mysqli->prepare('SELECT photo_blob, photo_mime FROM candidates_registration WHERE student_id = ? AND photo_blob IS NOT NULL LIMIT 1')) {
    $stmt->bind_param('s', $studentId);
    $stmt->execute();
    $stmt->store_result();
    if ($stmt->num_rows > 0) {
      $stmt->bind_result($blob, $mime);
      $stmt->fetch();
      if (stream_blob($blob, $mime)) { $stmt->close(); exit(); }
    }
    $stmt->close();
  }
}

if ($name !== '') {
  $full = $name;
  $parts = preg_split('/\s+/', trim($name));
  $first = $parts[0] ?? '';
  $last = $parts[count($parts)-1] ?? '';
  $like = '%' . $first . '%';
  if ($stmt = $mysqli->prepare("SELECT photo_blob, photo_mime FROM candidates_registration 
    WHERE (CONCAT_WS(' ', first_name, middle_name, last_name) = ? 
       OR CONCAT_WS(' ', first_name, last_name) = ? 
       OR (first_name = ? AND last_name = ?) 
       OR first_name LIKE ? OR last_name LIKE ?) 
      AND photo_blob IS NOT NULL 
    LIMIT 1")) {
    $stmt->bind_param('ssssss', $full, $full, $first, $last, $like, $like);
    $stmt->execute();
    $stmt->store_result();
    if ($stmt->num_rows > 0) {
      $stmt->bind_result($blob, $mime);
      $stmt->fetch();
      if (stream_blob($blob, $mime)) { $stmt->close(); exit(); }
    }
    $stmt->close();
  }
}

// 2) Fallback to filesystem patterns
function norm($s) {
  $s = strtolower($s);
  $s = preg_replace('/\s+/', '_', $s);
  $s = preg_replace('/[^a-z0-9_\-]/', '', $s);
  return $s;
}

$candidates = [];
if ($studentId !== '') $candidates[] = norm($studentId);
if ($name !== '') $candidates[] = norm($name);

if ($name !== '') {
  $parts = preg_split('/\s+/', trim($name));
  if (count($parts) >= 2) {
    $first = array_shift($parts);
    $last = array_pop($parts);
    $mid = count($parts) ? '_' . implode('_', $parts) : '';
    $candidates[] = norm($last . '_' . $first . $mid);
    $candidates[] = norm($first . '_' . $last . $mid);
  }
}

foreach ($candidates as $base) {
  foreach ($exts as $ext) {
    $p = $baseDir . '/' . $base . '.' . $ext;
    if (is_file($p)) {
      $mime = $ext === 'png' ? 'image/png' : ($ext === 'webp' ? 'image/webp' : 'image/jpeg');
      header('Content-Type: ' . $mime);
      header('Cache-Control: public, max-age=86400');
      readfile($p);
      exit();
    }
  }
}

http_response_code(404);
echo json_encode(['success' => false, 'message' => 'Photo not found']);
