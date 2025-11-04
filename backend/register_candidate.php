<?php
header('Content-Type: application/json');
require_once __DIR__ . '/config.php';

$mysqli = db_connect();
// Ensure mysqli does not throw exceptions that leak HTML stack traces
if (function_exists('mysqli_report')) { @mysqli_report(MYSQLI_REPORT_OFF); }

// Convert PHP warnings/notices into exceptions and always return JSON
set_error_handler(function ($severity, $message, $file, $line) {
  if (!(error_reporting() & $severity)) { return false; }
  throw new ErrorException($message, 0, $severity, $file, $line);
});
set_exception_handler(function ($e) {
  http_response_code(500);
  echo json_encode([
    'success' => false,
    'message' => 'Server error',
    'error' => $e->getMessage(),
    'file' => $e->getFile(),
    'line' => $e->getLine(),
  ]);
  exit();
});

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
  $candidate_type = trim($_POST['candidate_type'] ?? '');
  $party_name     = trim($_POST['party_name'] ?? '');
  $photo_url    = null;
  if (!empty($_FILES['photo']) && is_uploaded_file($_FILES['photo']['tmp_name'])) {
    $pubId = ($student_id !== '') ? $student_id : (preg_replace('/\s+/', '_', trim(($first_name.'_'.$last_name))) . '_' . time());
    list($ok, $url, $err) = cloudinary_upload($_FILES['photo']['tmp_name'], 'candidates', $pubId);
    if ($ok) { $photo_url = $url; }
  }
  // Optional party logo (multipart)
  $party_logo_url  = null;
  if (!empty($_FILES['party_logo']) && is_uploaded_file($_FILES['party_logo']['tmp_name'])) {
    $pname = $party_name !== '' ? $party_name : 'party_' . time();
    $pubId = strtolower(preg_replace('/[^a-zA-Z0-9_\-]+/','_', $pname));
    list($ok, $url, $err) = cloudinary_upload($_FILES['party_logo']['tmp_name'], 'party_logos', $pubId);
    if ($ok) { $party_logo_url = $url; }
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
  $candidate_type = isset($data['candidate_type']) ? trim($data['candidate_type']) : '';
  $party_name     = isset($data['party_name']) ? trim($data['party_name']) : '';
  $photo_b64    = $data['photo_base64'] ?? null;
  $photo_url    = null;
  if (is_string($photo_b64) && $photo_b64 !== '') {
    $decoded = base64_decode($photo_b64, true);
    if ($decoded !== false) {
      $tmp = tempnam(sys_get_temp_dir(), 'cphoto_');
      file_put_contents($tmp, $decoded);
      $pubId = ($student_id !== '') ? $student_id : (preg_replace('/\s+/', '_', trim(($first_name.'_'.$last_name))) . '_' . time());
      list($ok, $url, $err) = cloudinary_upload($tmp, 'candidates', $pubId);
      @unlink($tmp);
      if ($ok) { $photo_url = $url; }
    }
  }
  // Optional party logo via JSON (base64)
  $party_logo_b64  = $data['party_logo_base64'] ?? null;
  $party_logo_url  = null;
  if (is_string($party_logo_b64) && $party_logo_b64 !== '') {
    $decoded = base64_decode($party_logo_b64, true);
    if ($decoded !== false) {
      $tmp = tempnam(sys_get_temp_dir(), 'plogo_');
      file_put_contents($tmp, $decoded);
      $pname = $party_name !== '' ? $party_name : 'party_' . time();
      $pubId = strtolower(preg_replace('/[^a-zA-Z0-9_\-]+/','_', $pname));
      list($ok, $url, $err) = cloudinary_upload($tmp, 'party_logos', $pubId);
      @unlink($tmp);
      if ($ok) { $party_logo_url = $url; }
    }
  }
}

if ($student_id === '' || $first_name === '' || $last_name === '' || $organization === '' || $position === '' || $course === '' || $year_section === '' || $platform === '') {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Missing required fields']);
  exit();
}

// If candidate is Political Party, party_name must be provided
if ($candidate_type !== '' && strcasecmp($candidate_type, 'Political Party') === 0 && $party_name === '') {
  http_response_code(422);
  echo json_encode(['success' => false, 'message' => 'Party name is required for Political Party candidate']);
  exit();
}

// Enforce party nomination limits
if ($candidate_type !== '' && strcasecmp($candidate_type, 'Political Party') === 0 && $party_name !== '') {
  $quota = 1;
  $pos_norm = trim($position);
  $org_norm = trim($organization);
  $repPositions = ['BSIT Representative', 'BTLED Representative', 'BFPT Representative'];
  if (strcasecmp($org_norm, 'USG') === 0 && in_array($pos_norm, $repPositions, true)) {
    $quota = 2; // allow two reps per department per party
  }

  if ($stmtq = $mysqli->prepare("SELECT COUNT(*) FROM candidates_registration WHERE candidate_type = 'Political Party' AND party_name = ? AND organization = ? AND position = ?")) {
    $stmtq->bind_param('sss', $party_name, $org_norm, $pos_norm);
    $stmtq->execute();
    $stmtq->bind_result($cnt);
    $stmtq->fetch();
    $stmtq->close();
    if ((int)$cnt >= $quota) {
      http_response_code(409);
      $msg = ($quota === 1)
        ? 'This party already has a candidate for this position.'
        : 'This party already has the maximum number of representatives for this department.';
      echo json_encode(['success' => false, 'message' => $msg]);
      exit();
    }
  }
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
  candidate_type VARCHAR(50) NULL,
  party_name VARCHAR(150) NULL,
  photo_blob LONGBLOB NULL,
  photo_mime VARCHAR(64) NULL,
  party_logo_blob LONGBLOB NULL,
  party_logo_mime VARCHAR(64) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_student_org_position (student_id, organization, position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";

if (!$mysqli->query($createSql)) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed creating candidates table']);
  exit();
}

// Helpers: check column existence (compatible with MySQL/MariaDB without IF NOT EXISTS)
function column_exists(mysqli $mysqli, string $table, string $column): bool {
  $table_esc = $mysqli->real_escape_string($table);
  $column_esc = $mysqli->real_escape_string($column);
  $db = null;
  if ($resDb = @$mysqli->query('SELECT DATABASE() AS db')) {
    if ($row = $resDb->fetch_assoc()) {
      $db = $row['db'] ?? null;
    }
    $resDb->close();
  }
  if (!$db) { return false; }
  $db_esc = $mysqli->real_escape_string($db);
  $sql = "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='{$db_esc}' AND TABLE_NAME='{$table_esc}' AND COLUMN_NAME='{$column_esc}' LIMIT 1";
  if ($res = @$mysqli->query($sql)) {
    $exists = $res->num_rows > 0;
    $res->close();
    return $exists;
  }
  return false;
}

// Add missing URL columns and drop blob columns
if (!column_exists($mysqli, 'candidates_registration', 'photo_url')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN photo_url VARCHAR(1024) NULL");
}
@$mysqli->query("ALTER TABLE candidates_registration DROP COLUMN IF EXISTS photo_blob");
@$mysqli->query("ALTER TABLE candidates_registration DROP COLUMN IF EXISTS photo_mime");
if (!column_exists($mysqli, 'candidates_registration', 'candidate_type')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN candidate_type VARCHAR(50) NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'party_name')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_name VARCHAR(150) NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'party_logo_blob')) {
  // intentionally not creating blob column anymore
}
if (!column_exists($mysqli, 'candidates_registration', 'party_logo_mime')) {
  // intentionally not creating mime column anymore
}
if (!column_exists($mysqli, 'candidates_registration', 'party_logo_url')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_logo_url VARCHAR(1024) NULL");
}
@$mysqli->query("ALTER TABLE candidates_registration DROP COLUMN IF EXISTS party_logo_blob");
@$mysqli->query("ALTER TABLE candidates_registration DROP COLUMN IF EXISTS party_logo_mime");

// Prepare insert (robust to older schema)
$has_candidate_type_col = column_exists($mysqli, 'candidates_registration', 'candidate_type');
$has_party_name_col = column_exists($mysqli, 'candidates_registration', 'party_name');

$middle = ($middle_name === '') ? null : $middle_name;
$photo_url_val  = $photo_url;
$party_logo_url_val  = $party_logo_url;

if ($has_candidate_type_col && $has_party_name_col) {
  $sql = "INSERT INTO `candidates_registration`
    (`student_id`, `first_name`, `middle_name`, `last_name`, `organization`, `position`, `program`, `year_section`, `platform`, `candidate_type`, `party_name`, `photo_url`, `party_logo_url`)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
  if (!($stmt = $mysqli->prepare($sql))) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed preparing statement', 'error' => $mysqli->error]);
    exit();
  }
  $candidate_type_val = ($candidate_type === '' ? null : $candidate_type);
  $party_name_val = ($party_name === '' ? null : $party_name);
  $stmt->bind_param(
    'sssssssssssss',
    $student_id,
    $first_name,
    $middle,
    $last_name,
    $organization,
    $position,
    $course,
    $year_section,
    $platform,
    $candidate_type_val,
    $party_name_val,
    $photo_url_val,
    $party_logo_url_val
  );
} else {
  // Legacy fallback without candidate type/party name columns
  $sql = "INSERT INTO `candidates_registration`
    (`student_id`, `first_name`, `middle_name`, `last_name`, `organization`, `position`, `program`, `year_section`, `platform`, `photo_url`, `party_logo_url`)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
  if (!($stmt = $mysqli->prepare($sql))) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed preparing statement (legacy)', 'error' => $mysqli->error]);
    exit();
  }
  $stmt->bind_param(
    'sssssssssss',
    $student_id,
    $first_name,
    $middle,
    $last_name,
    $organization,
    $position,
    $course,
    $year_section,
    $platform,
    $photo_url_val,
    $party_logo_url_val
  );
}

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
