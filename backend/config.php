<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit();
}

$DB_HOST = 'localhost';
$DB_USER = 'root';
$DB_PASS = '';
$DB_NAME = 'societree_app';

function db_connect() {
  global $DB_HOST, $DB_USER, $DB_PASS, $DB_NAME;
  $mysqli = new mysqli($DB_HOST, $DB_USER, $DB_PASS);
  if ($mysqli->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'DB connection failed: ' . $mysqli->connect_error]);
    exit();
  }
  // Ensure database exists
  if (!$mysqli->query("CREATE DATABASE IF NOT EXISTS `$DB_NAME` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed creating database']);
    exit();
  }
  $mysqli->select_db($DB_NAME);

  // Ensure credentials table exists
  $create = "CREATE TABLE IF NOT EXISTS users (
      id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      email VARCHAR(255) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
  if (!$mysqli->query($create)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed creating table']);
    exit();
  }

  return $mysqli;
}

function read_json_body() {
  $raw = file_get_contents('php://input');
  $data = json_decode($raw, true);
  if (!is_array($data)) {
    return null;
  }
  return $data;
}
