<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit();
}

require_once __DIR__ . '/config.php';
$mysqli = db_connect();

$data = read_json_body();
if (!$data || !isset($data['candidate_id'])) {
  http_response_code(400);
  echo json_encode(['success' => false, 'message' => 'Missing candidate_id']);
  exit();
}

$candidateId = (int)$data['candidate_id'];

// Delete candidate from candidates_registration table
$stmt = $mysqli->prepare('DELETE FROM candidates_registration WHERE id = ?');
if (!$stmt) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed to prepare statement']);
  exit();
}

$stmt->bind_param('i', $candidateId);
if (!$stmt->execute()) {
  $stmt->close();
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed to delete candidate']);
  exit();
}

$affected = $mysqli->affected_rows;
$stmt->close();

if ($affected > 0) {
  echo json_encode(['success' => true, 'message' => 'Candidate deleted successfully']);
} else {
  http_response_code(404);
  echo json_encode(['success' => false, 'message' => 'Candidate not found']);
}


