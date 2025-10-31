<?php
require_once __DIR__ . '/config.php';
$mysqli = db_connect();

// Fetch candidates from candidates_registration table
$sql = "SELECT id, student_id, first_name, middle_name, last_name, organization, position, program, year_section, platform, created_at FROM candidates_registration ORDER BY created_at DESC, id DESC";

$res = $mysqli->query($sql);
if (!$res) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Query failed']);
  exit();
}

$candidates = [];
while ($row = $res->fetch_assoc()) {
  $candidates[] = [
    'id' => (int)$row['id'],
    'student_id' => $row['student_id'],
    'first_name' => $row['first_name'],
    'middle_name' => $row['middle_name'],
    'last_name' => $row['last_name'],
    'organization' => $row['organization'],
    'position' => $row['position'],
    'program' => $row['program'],
    'year_section' => $row['year_section'],
    'platform' => $row['platform'],
    'has_photo' => false,
    'created_at' => $row['created_at'],
  ];
}
$res->free();

echo json_encode(['success' => true, 'candidates' => $candidates]);
