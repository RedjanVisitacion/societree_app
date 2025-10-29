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

  Future<Map<String, dynamic>> register({required String studentId, required String password}) async {
    final uri = Uri.parse('$baseUrl/register.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'student_id': studentId, 'password': password}))
        .timeout(_timeout);
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
