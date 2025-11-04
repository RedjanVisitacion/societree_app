<?php
header('Content-Type: application/json');
require_once __DIR__ . '/config.php';

$mysqli = db_connect();
if (function_exists('mysqli_report')) { @mysqli_report(MYSQLI_REPORT_OFF); }

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
  ]);
  exit();
});

// Helpers reused from register script
function column_exists(mysqli $mysqli, string $table, string $column): bool {
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

// Ensure table exists (same as register)
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
@$mysqli->query($createSql);
if (!column_exists($mysqli, 'candidates_registration', 'candidate_type')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN candidate_type VARCHAR(50) NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'party_name')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_name VARCHAR(150) NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'photo_blob')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN photo_blob LONGBLOB NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'photo_mime')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN photo_mime VARCHAR(64) NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'party_logo_blob')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_logo_blob LONGBLOB NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'party_logo_mime')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_logo_mime VARCHAR(64) NULL");
}

// Parse input (multipart or JSON)
$isMultipart = (isset($_SERVER['CONTENT_TYPE']) && stripos($_SERVER['CONTENT_TYPE'], 'multipart/form-data') !== false) || !empty($_POST);
if ($isMultipart) {
  $cid           = isset($_POST['candidate_id']) ? (int)$_POST['candidate_id'] : 0;
  $student_id    = isset($_POST['student_id']) ? trim($_POST['student_id']) : null;
  $first_name    = isset($_POST['first_name']) ? trim($_POST['first_name']) : null;
  $middle_name   = array_key_exists('middle_name', $_POST) ? trim($_POST['middle_name']) : null; // allow empty -> set NULL
  $last_name     = isset($_POST['last_name']) ? trim($_POST['last_name']) : null;
  $organization  = isset($_POST['organization']) ? trim($_POST['organization']) : null;
  $position      = isset($_POST['position']) ? trim($_POST['position']) : null;
  $course        = isset($_POST['course']) ? trim($_POST['course']) : null;
  $year_section  = isset($_POST['year_section']) ? trim($_POST['year_section']) : null;
  $platform      = isset($_POST['platform']) ? trim($_POST['platform']) : null;
  $candidate_type= array_key_exists('candidate_type', $_POST) ? trim($_POST['candidate_type']) : null;
  $party_name    = array_key_exists('party_name', $_POST) ? trim($_POST['party_name']) : null;
  $provided      = $_POST;

  $photo_blob = null; $photo_mime = null; $photo_received = false; $photo_saved = false; $photo_error = null; $photo_url = null;
  if (!empty($_FILES['photo']) && is_uploaded_file($_FILES['photo']['tmp_name'])) {
    $photo_received = true;
    $ext = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
    if ($ext === 'png') $photo_mime = 'image/png';
    elseif ($ext === 'jpg' || $ext === 'jpeg') $photo_mime = 'image/jpeg';
    elseif ($ext === 'webp') $photo_mime = 'image/webp';
    else $photo_mime = 'application/octet-stream';
    $size = (int)($_FILES['photo']['size'] ?? 0);
    if ($size > 0) {
      $pubId = ($student_id && $student_id !== '') ? $student_id : ( ($first_name ?? '') . '_' . ($last_name ?? '') . '_' . time());
      list($ok, $url, $err) = cloudinary_upload($_FILES['photo']['tmp_name'], 'candidates', $pubId);
      if ($ok) { $photo_url = $url; $photo_saved = true; $photo_blob = null; $photo_mime = null; }
      else { $photo_error = $err; }
    }
  } elseif (!empty($_FILES['photo'])) {
    // present but not a valid uploaded file
    $photo_received = true;
    $photo_error = $_FILES['photo']['error'] ?? 'unknown';
  }
  $party_logo_blob = null; $party_logo_mime = null; $logo_received = false; $logo_saved = false; $logo_error = null; $party_logo_url = null;
  if (!empty($_FILES['party_logo']) && is_uploaded_file($_FILES['party_logo']['tmp_name'])) {
    $logo_received = true;
    $ext = strtolower(pathinfo($_FILES['party_logo']['name'], PATHINFO_EXTENSION));
    if ($ext === 'png') $party_logo_mime = 'image/png';
    elseif ($ext === 'jpg' || $ext === 'jpeg') $party_logo_mime = 'image/jpeg';
    elseif ($ext === 'webp') $party_logo_mime = 'image/webp';
    else $party_logo_mime = 'application/octet-stream';
    $size = (int)($_FILES['party_logo']['size'] ?? 0);
    if ($size > 0) {
      $pname = ($party_name ?? '') !== '' ? $party_name : ('party_' . time());
      $pubId = preg_replace('/[^a-zA-Z0-9_\-]+/','_', strtolower($pname));
      list($ok, $url, $err) = cloudinary_upload($_FILES['party_logo']['tmp_name'], 'party_logos', $pubId);
      if ($ok) { $party_logo_url = $url; $logo_saved = true; $party_logo_blob = null; $party_logo_mime = null; }
      else { $logo_error = $err; }
    }
  } elseif (!empty($_FILES['party_logo'])) {
    $logo_received = true;
    $logo_error = $_FILES['party_logo']['error'] ?? 'unknown';
  }
} else {
  $data = read_json_body();
  $cid           = isset($data['candidate_id']) ? (int)$data['candidate_id'] : 0;
  $student_id    = is_array($data) && array_key_exists('student_id', $data) ? trim($data['student_id']) : null;
  $first_name    = is_array($data) && array_key_exists('first_name', $data) ? trim($data['first_name']) : null;
  $middle_name   = is_array($data) && array_key_exists('middle_name', $data) ? trim($data['middle_name']) : null;
  $last_name     = is_array($data) && array_key_exists('last_name', $data) ? trim($data['last_name']) : null;
  $organization  = is_array($data) && array_key_exists('organization', $data) ? trim($data['organization']) : null;
  $position      = is_array($data) && array_key_exists('position', $data) ? trim($data['position']) : null;
  $course        = is_array($data) && array_key_exists('course', $data) ? trim($data['course']) : null;
  $year_section  = is_array($data) && array_key_exists('year_section', $data) ? trim($data['year_section']) : null;
  $platform      = is_array($data) && array_key_exists('platform', $data) ? trim($data['platform']) : null;
  $candidate_type= is_array($data) && array_key_exists('candidate_type', $data) ? trim($data['candidate_type']) : null;
  $party_name    = is_array($data) && array_key_exists('party_name', $data) ? trim($data['party_name']) : null;
  $photo_blob = null; $photo_mime = null; $party_logo_blob = null; $party_logo_mime = null; // JSON path omits file updates
  $provided = is_array($data) ? $data : [];
}

if ($cid <= 0) {
  http_response_code(400);
  echo json_encode(['success' => false, 'message' => 'candidate_id is required']);
  exit();
}

$fields = [];
$params = [];
$types  = '';

// Helper: whether a key was provided in input
$wasProvided = function(string $k) use ($provided): bool { return is_array($provided) && array_key_exists($k, $provided); };

// Only update fields that are provided (null means set NULL, missing means ignore)
$map = [
  'student_id'     => $student_id,
  'first_name'     => $first_name,
  'middle_name'    => ($wasProvided('middle_name') ? ($middle_name === '' ? null : $middle_name) : null),
  'last_name'      => $last_name,
  'organization'   => $organization,
  'position'       => $position,
  // DB column is program, input key is course
  'program'        => $course,
  'year_section'   => $year_section,
  'platform'       => $platform,
  'candidate_type' => ($wasProvided('candidate_type') ? ($candidate_type === '' ? null : $candidate_type) : null),
  'party_name'     => ($wasProvided('party_name') ? ($party_name === '' ? null : $party_name) : null),
];
// Ensure URL columns exist
if (!column_exists($mysqli, 'candidates_registration', 'photo_url')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN photo_url VARCHAR(1024) NULL");
}
if (!column_exists($mysqli, 'candidates_registration', 'party_logo_url')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_logo_url VARCHAR(1024) NULL");
}

foreach ($map as $col => $val) {
  $inputKey = ($col === 'program') ? 'course' : $col;
  if ($wasProvided($inputKey)) {
    $fields[] = "$col = ?";
    $params[] = $val; $types .= 's';
  }
}
if ($photo_url !== null) { $fields[] = 'photo_url = ?'; $params[] = $photo_url; $types .= 's'; $fields[] = 'photo_blob = NULL'; $fields[] = 'photo_mime = NULL'; }
elseif ($photo_blob !== null) { $fields[] = 'photo_blob = ?'; $params[] = $photo_blob; $types .= 'b'; if ($photo_mime !== null) { $fields[] = 'photo_mime = ?'; $params[] = $photo_mime; $types .= 's'; } }
elseif ($photo_mime !== null) { $fields[] = 'photo_mime = ?'; $params[] = $photo_mime; $types .= 's'; }
if ($party_logo_url !== null) { $fields[] = 'party_logo_url = ?'; $params[] = $party_logo_url; $types .= 's'; $fields[] = 'party_logo_blob = NULL'; $fields[] = 'party_logo_mime = NULL'; }
elseif ($party_logo_blob !== null) { $fields[] = 'party_logo_blob = ?'; $params[] = $party_logo_blob; $types .= 'b'; if ($party_logo_mime !== null) { $fields[] = 'party_logo_mime = ?'; $params[] = $party_logo_mime; $types .= 's'; } }
elseif ($party_logo_mime !== null) { $fields[] = 'party_logo_mime = ?'; $params[] = $party_logo_mime; $types .= 's'; }

if (empty($fields)) {
  echo json_encode(['success' => true, 'message' => 'Nothing to update']);
  exit();
}

$sql = 'UPDATE candidates_registration SET ' . implode(', ', $fields) . ' WHERE id = ? LIMIT 1';
$stmt = $mysqli->prepare($sql);
if (!$stmt) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed preparing update statement']);
  exit();
}
$types .= 'i';
$params[] = $cid;

// bind_param needs references
$bindParams = [];
$bindParams[] = $types;
for ($i = 0; $i < count($params); $i++) { $bindParams[] = &$params[$i]; }
call_user_func_array([$stmt, 'bind_param'], $bindParams);

if (!$stmt->execute()) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Update failed']);
  $stmt->close();
  exit();
}
$stmt->close();

$msgParts = [];
$msgParts[] = 'Candidate updated';
if (isset($photo_received)) {
  if ($photo_received) {
    if ($photo_saved) { $msgParts[] = '(photo saved)'; }
    else if ($photo_error !== null) { $msgParts[] = '(photo upload error: ' . $photo_error . ')'; }
    else { $msgParts[] = '(photo not saved)'; }
  } else {
    $msgParts[] = '(no new photo)';
  }
}
if (isset($logo_received)) {
  if ($logo_received) {
    if ($logo_saved) { $msgParts[] = '(logo saved)'; }
    else if ($logo_error !== null) { $msgParts[] = '(logo upload error: ' . $logo_error . ')'; }
    else { $msgParts[] = '(logo not saved)'; }
  } else {
    $msgParts[] = '(no new logo)';
  }
}

echo json_encode(['success' => true, 'message' => implode(' ', $msgParts)]);
