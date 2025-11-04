<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
// Prevent PHP notices/warnings from polluting JSON responses
@ini_set('display_errors', '0');
@error_reporting(0);
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

  // Ensure users table exists (supports student_id, role, department, position)
  $create = "CREATE TABLE IF NOT EXISTS users (
      id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      student_id VARCHAR(64) UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      role VARCHAR(32) NOT NULL DEFAULT 'user',
      department VARCHAR(128) NULL,
      position VARCHAR(128) NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
  if (!$mysqli->query($create)) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed creating table']);
    exit();
  }

  // In case table exists from older version, ensure columns and indexes exist
  $mysqli->query("ALTER TABLE users ADD COLUMN IF NOT EXISTS student_id VARCHAR(64) NULL");
  $mysqli->query("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_student_id ON users (student_id)");
  $mysqli->query("ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(32) NOT NULL DEFAULT 'user'");
  $mysqli->query("ALTER TABLE users ADD COLUMN IF NOT EXISTS department VARCHAR(128) NULL");
  $mysqli->query("ALTER TABLE users ADD COLUMN IF NOT EXISTS position VARCHAR(128) NULL");
  // Try to drop old email column if it exists (MySQL 8+ supports IF EXISTS)
  $mysqli->query("ALTER TABLE users DROP COLUMN IF EXISTS email");

  // Seed/ensure default admin user
  $defaultId = '2023304637';
  $defaultPass = '12345678';
  $defaultPassHash = password_hash($defaultPass, PASSWORD_BCRYPT);
  if ($stmt = $mysqli->prepare('SELECT id, password_hash FROM users WHERE student_id = ?')) {
    $stmt->bind_param('s', $defaultId);
    $stmt->execute();
    $stmt->bind_result($uid, $phash);
    if ($stmt->fetch()) {
      $stmt->close();
      // Update password if needed and ensure role/department are correct
      if (!password_verify($defaultPass, $phash)) {
        if ($upd = $mysqli->prepare('UPDATE users SET password_hash = ? WHERE student_id = ?')) {
          $upd->bind_param('ss', $defaultPassHash, $defaultId);
          $upd->execute();
          $upd->close();
        }
      }
      if ($upd2 = $mysqli->prepare("UPDATE users SET role = 'admin', department = 'BSIT', position = 'ElecomChairPerson' WHERE student_id = ? AND (
          role <> 'admin' OR role IS NULL OR
          department <> 'BSIT' OR department IS NULL OR
          position <> 'ElecomChairPerson' OR position IS NULL
        )")) {
        $upd2->bind_param('s', $defaultId);
        $upd2->execute();
        $upd2->close();
      }
    } else {
      $stmt->close();
      if ($ins = $mysqli->prepare("INSERT INTO users (student_id, password_hash, role, department, position) VALUES (?, ?, 'admin', 'BSIT', 'ElecomChairPerson')")) {
        $ins->bind_param('ss', $defaultId, $defaultPassHash);
        $ins->execute();
        $ins->close();
      }
    }
  }

  return $mysqli;
}

function read_json_body() {
  $raw = file_get_contents('php://input');
  if ($raw === false) { return null; }
  $raw = ltrim($raw);
  if (strncmp($raw, "\xEF\xBB\xBF", 3) === 0) {
    $raw = substr($raw, 3);
  }
  if ($raw === '' || $raw === null) { return null; }
  $data = json_decode($raw, true);
  if (json_last_error() !== JSON_ERROR_NONE || !is_array($data)) {
    return null;
  }
  return $data;
}

define('CLOUDINARY_CLOUD', 'dhhzkqmso');
define('CLOUDINARY_KEY', '871914741883427');
define('CLOUDINARY_SECRET', 'ihwwUCjI92s8tBpm24Vqj2CIWJk');

function cloudinary_upload(string $filePath, string $folder, string $publicId = '') {
  if (!is_file($filePath)) { return [false, null, 'file']; }
  $cloud = CLOUDINARY_CLOUD; $key = CLOUDINARY_KEY; $secret = CLOUDINARY_SECRET;
  if (!$cloud || !$key || !$secret) { return [false, null, 'config']; }
  $url = 'https://api.cloudinary.com/v1_1/' . $cloud . '/image/upload';
  $timestamp = time();
  $params = ['folder' => $folder, 'timestamp' => $timestamp];
  if ($publicId !== '') { $params['public_id'] = $publicId; }
  ksort($params);
  $toSign = '';
  foreach ($params as $k => $v) { if ($toSign !== '') { $toSign .= '&'; } $toSign .= $k . '=' . $v; }
  $signature = sha1($toSign . $secret);
  $post = [
    'api_key' => $key,
    'timestamp' => $timestamp,
    'signature' => $signature,
    'folder' => $folder,
  ];
  if ($publicId !== '') { $post['public_id'] = $publicId; }
  if (function_exists('curl_file_create')) {
    $post['file'] = curl_file_create($filePath);
  } else {
    $post['file'] = '@' . $filePath;
  }
  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  $res = curl_exec($ch);
  if ($res === false) { $err = curl_error($ch); curl_close($ch); return [false, null, $err ?: 'curl']; }
  $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  $data = json_decode($res, true);
  if ($code >= 200 && $code < 300 && isset($data['secure_url'])) { return [true, $data['secure_url'], null]; }
  return [false, null, isset($data['error']['message']) ? $data['error']['message'] : 'upload'];
}
