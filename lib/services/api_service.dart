import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  static const Duration _timeout = Duration(seconds: 10);

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> login({required String studentId, required String password}) async {
    final uri = Uri.parse('$baseUrl/login.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'student_id': studentId, 'password': password}))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> registerCandidateBase64({
    required String studentId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String organization,
    required String position,
    required String course,
    required String yearSection,
    required String platform,
    String? candidateType,
    String? partyName,
    String? photoBase64,
    String? photoMimeType,
  }) async {
    final uri = Uri.parse('$baseUrl/register_candidate.php');
    final payload = {
      'student_id': studentId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'organization': organization,
      'position': position,
      'course': course,
      'year_section': yearSection,
      'platform': platform,
      if (candidateType != null && candidateType.isNotEmpty) 'candidate_type': candidateType,
      if (partyName != null && partyName.isNotEmpty) 'party_name': partyName,
      if (photoBase64 != null && photoBase64.isNotEmpty) 'photo_base64': photoBase64,
      if (photoMimeType != null && photoMimeType.isNotEmpty) 'photo_mime': photoMimeType,
    };
    final res = await http.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    ).timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> register({required String studentId, required String password}) async {
    final uri = Uri.parse('$baseUrl/register.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'student_id': studentId, 'password': password}))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> registerCandidate({
    required String studentId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String organization,
    required String position,
    required String course,
    required String yearSection,
    required String platform,
    String? candidateType,
    String? partyName,
    required String photoUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/register_candidate.php');
    final payload = {
      'student_id': studentId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'organization': organization,
      'position': position,
      'course': course,
      'year_section': yearSection,
      'platform': platform,
      if (candidateType != null && candidateType.isNotEmpty) 'candidate_type': candidateType,
      if (partyName != null && partyName.isNotEmpty) 'party_name': partyName,
      'photo_url': photoUrl,
    };
    final res = await http.post(uri, headers: _jsonHeaders, body: jsonEncode(payload)).timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> registerCandidateMultipart({
    required String studentId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String organization,
    required String position,
    required String course,
    required String yearSection,
    required String platform,
    String? candidateType,
    String? partyName,
    String? photoFilePath,
    String? partyLogoFilePath,
  }) async {
    final uri = Uri.parse('$baseUrl/register_candidate.php');
    final req = http.MultipartRequest('POST', uri);
    req.fields.addAll({
      'student_id': studentId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'organization': organization,
      'position': position,
      'course': course,
      'year_section': yearSection,
      'platform': platform,
    });
    if (candidateType != null && candidateType.isNotEmpty) {
      req.fields['candidate_type'] = candidateType;
    }
    if (partyName != null && partyName.isNotEmpty) {
      req.fields['party_name'] = partyName;
    }
    if (photoFilePath != null && photoFilePath.isNotEmpty) {
      try {
        req.files.add(await http.MultipartFile.fromPath('photo', photoFilePath));
      } catch (_) {
        // ignore silently; server will handle missing photo
      }
    }
    if (partyLogoFilePath != null && partyLogoFilePath.isNotEmpty) {
      try {
        req.files.add(await http.MultipartFile.fromPath('party_logo', partyLogoFilePath));
      } catch (_) {
      }
    }
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Debug: log non-2xx JSON responses
        // ignore: avoid_print
        print('API ${res.request?.url} -> ${res.statusCode} JSON: ${res.body}');
        return {
          'success': body['success'] == true,
          'message': body['message'] ?? 'Request failed',
          'status': res.statusCode,
        };
      }
      return body;
    } catch (_) {
      // Debug: log invalid JSON responses
      final raw = res.body;
      // ignore: avoid_print
      print('API ${res.request?.url} -> ${res.statusCode} RAW: ${raw.substring(0, raw.length > 300 ? 300 : raw.length)}');
      return {
        'success': false,
        'message': 'Invalid server response',
        'status': res.statusCode,
        'raw': raw,
      };
    }
  }
}

