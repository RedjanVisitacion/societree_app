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
if (!$data || !isset($data['party_name'])) {
  http_response_code(400);
  echo json_encode(['success' => false, 'message' => 'Missing party_name']);
  exit();
}

$partyName = trim($data['party_name']);
if (empty($partyName)) {
  http_response_code(400);
  echo json_encode(['success' => false, 'message' => 'Party name cannot be empty']);
  exit();
}

// Delete all candidates with this party name
$stmt = $mysqli->prepare('DELETE FROM candidates_registration WHERE party_name = ? AND candidate_type = ?');
if (!$stmt) {
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed to prepare statement']);
  exit();
}

$candidateType = 'Political Party';
$stmt->bind_param('ss', $partyName, $candidateType);
if (!$stmt->execute()) {
  $stmt->close();
  http_response_code(500);
  echo json_encode(['success' => false, 'message' => 'Failed to delete party']);
  exit();
}

$affected = $mysqli->affected_rows;
$stmt->close();

if ($affected > 0) {
  echo json_encode(['success' => true, 'message' => 'Party deleted successfully', 'deleted_count' => $affected]);
} else {
  http_response_code(404);
  echo json_encode(['success' => false, 'message' => 'Party not found']);
}



