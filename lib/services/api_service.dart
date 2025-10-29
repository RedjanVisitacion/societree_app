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

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/login.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'email': email, 'password': password}))
        .timeout(_timeout);
    return _decode(res);
  }

  Future<Map<String, dynamic>> register({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/register.php');
    final res = await http
        .post(uri, headers: _jsonHeaders, body: jsonEncode({'email': email, 'password': password}))
        .timeout(_timeout);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return {
          'success': body['success'] == true,
          'message': body['message'] ?? 'Request failed',
          'status': res.statusCode,
        };
      }
      return body;
    } catch (_) {
      final raw = res.body;
      return {
        'success': false,
        'message': 'Invalid server response',
        'status': res.statusCode,
        'raw': raw,
      };
    }
  }
}
