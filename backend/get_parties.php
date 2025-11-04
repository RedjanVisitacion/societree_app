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
  echo json_encode(['success' => false, 'message' => 'Server error']);
  exit();
});

// Ensure table exists similarly to register script
@$mysqli->query("CREATE TABLE IF NOT EXISTS candidates_registration (
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
  photo_url VARCHAR(1024) NULL,
  party_logo_url VARCHAR(1024) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_student_org_position (student_id, organization, position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

function column_exists_local(mysqli $mysqli, string $table, string $column): bool {
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

if (!column_exists_local($mysqli, 'candidates_registration', 'party_logo_url')) {
  @$mysqli->query("ALTER TABLE candidates_registration ADD COLUMN party_logo_url VARCHAR(1024) NULL");
}

$has_blob = column_exists_local($mysqli, 'candidates_registration', 'party_logo_blob');
$has_url = column_exists_local($mysqli, 'candidates_registration', 'party_logo_url');
$has_expr = "CASE WHEN party_logo_url IS NOT NULL AND party_logo_url <> '' THEN 1 ELSE 0 END";
if ($has_blob) { $has_expr = $has_expr . " OR CASE WHEN party_logo_blob IS NOT NULL THEN 1 ELSE 0 END"; }

// Fetch unique party names with logo presence
$sql = "SELECT party_name,
               MAX($has_expr) AS has_logo,
               MAX(party_logo_url) AS logo_url
        FROM candidates_registration
        WHERE candidate_type = 'Political Party' AND party_name IS NOT NULL AND party_name <> ''
        GROUP BY party_name
        ORDER BY party_name";

$res = @$mysqli->query($sql);
if (!$res) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Query failed']);
  exit();
}
$rows = [];
while ($row = $res->fetch_assoc()) {
  $rows[] = [
    'party_name' => $row['party_name'],
    'has_logo' => (bool)$row['has_logo'],
    'logo_url' => $row['logo_url'] ?? null,
  ];
}
$res->close();

echo json_encode(['success' => true, 'parties' => $rows]);
