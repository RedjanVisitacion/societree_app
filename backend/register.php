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

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Valid email required']);
  exit();
}
if (strlen($password) < 6) {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Password too short']);
  exit();
}

$mysqli = db_connect();

// Check existing
$stmt = $mysqli->prepare('SELECT id FROM users WHERE email = ?');
$stmt->bind_param('s', $email);
$stmt->execute();
$stmt->store_result();
if ($stmt->num_rows > 0) {
  http_response_code(409);
  echo json_encode(['success' => false, 'message' => 'Email already registered']);
  $stmt->close();
  $mysqli->close();
  exit();
}
$stmt->close();

$hash = password_hash($password, PASSWORD_BCRYPT);
$stmt = $mysqli->prepare('INSERT INTO users (email, password_hash) VALUES (?, ?)');
$stmt->bind_param('ss', $email, $hash);
if ($stmt->execute()) {
  echo json_encode(['success' => true, 'message' => 'Registered successfully']);
} else {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Registration failed']);
}
$stmt->close();
$mysqli->close();
