<?php
require_once __DIR__ . '/config.php';

$mysqli = db_connect();
// Ensure mysqli does not throw exceptions that leak HTML stack traces
if (function_exists('mysqli_report')) { @mysqli_report(MYSQLI_REPORT_OFF); }

// Support both JSON and multipart/form-data
$isMultipart = (isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false) || !empty($_POST);
if ($isMultipart) {
  $student_id   = trim($_POST['student_id'] ?? '');
  $first_name   = trim($_POST['first_name'] ?? '');
  $middle_name  = trim($_POST['middle_name'] ?? '');
  $last_name    = trim($_POST['last_name'] ?? '');
  $organization = trim($_POST['organization'] ?? '');
  $position     = trim($_POST['position'] ?? '');
  $course       = trim($_POST['course'] ?? '');
  $year_section = trim($_POST['year_section'] ?? '');
  $platform     = trim($_POST['platform'] ?? '');
  $photo_blob   = null;
  $photo_mime   = null;
  if (!empty($_FILES['photo']) && is_uploaded_file($_FILES['photo']['tmp_name'])) {
    $photo_blob = file_get_contents($_FILES['photo']['tmp_name']);
    $ext = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
    if ($ext === 'png') $photo_mime = 'image/png';
    elseif ($ext === 'jpg' || $ext === 'jpeg') $photo_mime = 'image/jpeg';
    elseif ($ext === 'webp') $photo_mime = 'image/webp';
    else $photo_mime = 'application/octet-stream';
  }
} else {
  $data = read_json_body();
  if ($data === null) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid body']);
    exit();
  }
  $student_id   = trim($data['student_id'] ?? '');
  $first_name   = trim($data['first_name'] ?? '');
  $middle_name  = trim($data['middle_name'] ?? '');
  $last_name    = trim($data['last_name'] ?? '');
  $organization = trim($data['organization'] ?? '');
  $position     = trim($data['position'] ?? '');
  $course       = trim($data['course'] ?? ''); // program
  $year_section = trim($data['year_section'] ?? '');
  $platform     = trim($data['platform'] ?? '');
  $photo_b64    = $data['photo_base64'] ?? null;
  $photo_mime   = isset($data['photo_mime']) ? trim($data['photo_mime']) : null;
  $photo_blob   = null;
  if (is_string($photo_b64) && $photo_b64 !== '') {
    $decoded = base64_decode($photo_b64, true);
    if ($decoded !== false) {
      $photo_blob = $decoded;
      if (!$photo_mime) { $photo_mime = 'application/octet-stream'; }
    }
  }
}

if ($student_id === '' || $first_name === '' || $last_name === '' || $organization === '' || $position === '' || $course === '' || $year_section === '' || $platform === '') {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Missing required fields']);
  exit();
}

// Ensure table exists
$createSql = "CREATE TABLE IF NOT EXISTS candidates_registration (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id VARCHAR(64) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100) NULL,
  last_name VARCHAR(100) NOT NULL,
  organization VARCHAR(100) NOT NULL,
  position VARCHAR(150) NOT NULL,
  program VARCHAR(50) NOT NULL,
  year_section VARCHAR(100) NOT NULL,
  platform TEXT NOT NULL,
  photo_blob LONGBLOB NULL,
  photo_mime VARCHAR(64) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_student_org_position (student_id, organization, position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

if (!$mysqli->query($createSql)) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed creating candidates table']);
  exit();
}

// In case table existed previously without new columns (MySQL 8+ IF NOT EXISTS)
@$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN IF NOT EXISTS photo_blob LONGBLOB NULL");
@$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN IF NOT EXISTS photo_mime VARCHAR(64) NULL");
@$mysqli->query("ALTER TABLE candidates_registration DROP COLUMN IF EXISTS photo_url");

// Prepare insert
$sql = "INSERT INTO candidates_registration
  (student_id, first_name, middle_name, last_name, organization, position, program, year_section, platform, photo_blob, photo_mime)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

if (!($stmt = $mysqli->prepare($sql))) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed preparing statement']);
  exit();
}

$middle = ($middle_name === '') ? null : $middle_name;
$photo_blob_val = $photo_blob; // may be null
$photo_mime_val = $photo_mime ? $photo_mime : null;

$stmt->bind_param(
  'sssssssssss',
  $student_id,
  $first_name,
  $middle,
  $last_name,
  $organization,
  $position,
  $course,       // stored as program column
  $year_section,
  $platform,
  $photo_blob_val,
  $photo_mime_val
);

try {
  if (!$stmt->execute()) {
    $err = $stmt->error;
    $code = ($mysqli->errno === 1062) ? 409 : 500; // duplicate -> conflict
    http_response_code($code);
    echo json_encode(['success' => false, 'message' => ($code === 409 ? 'Candidate already registered for this organization and position' : 'Insert failed'), 'error' => $err]);
    $stmt->close();
    exit();
  }
} catch (Throwable $e) {
  // Handle duplicate key gracefully when mysqli is configured to throw exceptions
  $code = ($e->getCode() === 1062 || strpos($e->getMessage(), '1062') !== false) ? 409 : 500;
  http_response_code($code);
  $msg = ($code === 409) ? 'Candidate already registered for this organization and position' : 'Insert failed';
  echo json_encode(['success' => false, 'message' => $msg]);
  $stmt->close();
  exit();
}

$stmt->close();
echo json_encode(['success' => true, 'message' => 'Candidate registered']);
