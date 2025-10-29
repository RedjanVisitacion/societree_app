<?php
require_once __DIR__ . '/config.php';

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

$email = isset($payload['email']) ? trim($payload['email']) : '';
$password = isset($payload['password']) ? (string)$payload['password'] : '';

if ($email === '' || $password === '') {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Email and password required']);
  exit();
}

$mysqli = db_connect();

$stmt = $mysqli->prepare('SELECT id, password_hash FROM users WHERE email = ?');
$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->bind_result($id, $hash);
if ($stmt->fetch()) {
  if (password_verify($password, $hash)) {
    echo json_encode(['success' => true, 'message' => 'Login successful', 'user_id' => $id]);
  } else {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
  }
} else {
  http_response_code(401);
  echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
}
$stmt->close();
$mysqli->close();
