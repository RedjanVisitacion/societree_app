<?php
require_once __DIR__ . '/config.php';

// Backward-compatible prefix check for PHP < 8
if (!function_exists('starts_with')) {
  function starts_with(string $haystack, string $prefix): bool {
    return substr($haystack, 0, strlen($prefix)) === $prefix;
  }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(['success' => false, 'message' => 'Method not allowed']);
  exit();
}

$payload = read_json_body();
if ($payload === null) {
  http_response_code(400);
  echo json_encode(['success' => false, 'message' => 'Invalid JSON']);
  exit();
}

$student_id = isset($payload['student_id']) ? trim($payload['student_id']) : '';
$password = isset($payload['password']) ? (string)$payload['password'] : '';

if ($student_id === '' || $password === '') {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Student ID and password required', 'student_id_received' => $student_id, 'student_id_len' => strlen($student_id)]);
  exit();
}

$mysqli = db_connect();

$stmt = $mysqli->prepare('SELECT id, password_hash, role, department, position FROM users WHERE student_id = ?');
$stmt->bind_param('s', $student_id);
$stmt->execute();
$stmt->bind_result($id, $hash, $role, $department, $position);
if ($stmt->fetch()) {
  // Accept only:
  // 1) plaintext verified against stored bcrypt
  // 2) legacy plaintext stored passwords (exact match), which are upgraded to bcrypt
  $storedIsBcrypt = starts_with($hash, '$2y$') || starts_with($hash, '$2a$') || starts_with($hash, '$2b$');
  $ok = password_verify($password, $hash)
        || (!$storedIsBcrypt && hash_equals($password, $hash));
  // Close the SELECT statement before any further queries to avoid 'Commands out of sync'
  $stmt->close();
  if ($ok) {
    // If the stored password is legacy plaintext, upgrade it to bcrypt now.
    if (!$storedIsBcrypt) {
      $newHash = password_hash($password, PASSWORD_BCRYPT);
      if ($upd = $mysqli->prepare('UPDATE users SET password_hash = ? WHERE id = ?')) {
        $upd->bind_param('si', $newHash, $id);
        $upd->execute();
        $upd->close();
      }
    }
    echo json_encode([
      'success' => true,
      'message' => 'Login successful',
      'user_id' => $id,
      'role' => $role,
      'department' => $department,
      'position' => $position,
    ]);
  } else {
    http_response_code(401);
    $hashPrefix = substr($hash, 0, 7);
    echo json_encode([
      'success' => false,
      'message' => 'Wrong password',
      'student_id_received' => $student_id,
      'hash_prefix' => $hashPrefix,
      'hash_len' => strlen($hash),
    ]);
  }
} else {
  http_response_code(401);
  // Close the SELECT statement when user not found
  $stmt->close();
  echo json_encode(['success' => false, 'message' => 'User not found', 'student_id_received' => $student_id, 'student_id_len' => strlen($student_id)]);
}
$mysqli->close();
