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
  photo_blob LONGBLOB NULL,
  photo_mime VARCHAR(64) NULL,
  party_logo_blob LONGBLOB NULL,
  party_logo_mime VARCHAR(64) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_student_org_position (student_id, organization, position)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

// Fetch unique party names with logo presence
$sql = "SELECT party_name, (party_logo_blob IS NOT NULL) AS has_logo
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
  ];
}
$res->close();

echo json_encode(['success' => true, 'parties' => $rows]);
