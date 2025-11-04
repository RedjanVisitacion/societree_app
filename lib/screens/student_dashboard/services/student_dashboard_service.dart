import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:societree_app/config/api_config.dart';

class StudentDashboardService {
  static Future<List<Map<String, dynamic>>> loadParties() async {
    try {
      final baseUrl = apiBaseUrl;
      final uri = Uri.parse('$baseUrl/get_parties.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List<dynamic> raw = body['parties'] ?? [];
        final items = raw.map<Map<String, dynamic>>((e) {
          final name = (e['party_name'] ?? '').toString();
          final hasLogo = e['has_logo'] == true || e['has_logo'] == 1;
          final direct = (e['logo_url'] ?? '').toString();
          final cb = DateTime.now().millisecondsSinceEpoch.toString();
          final logoUrl = hasLogo
              ? (direct.isNotEmpty
                  ? direct
                  : ('$baseUrl/get_party_logo.php?name=' + Uri.encodeComponent(name) + '&cb=' + cb))
              : null;
          return {'name': name, 'logoUrl': logoUrl};
        }).toList();
        return items;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> loadCandidates() async {
    try {
      final baseUrl = apiBaseUrl;
      final uri = Uri.parse('$baseUrl/get_candidates.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body);
      List<dynamic> raw;
      if (decoded is List) {
        raw = decoded;
      } else if (decoded is Map<String, dynamic>) {
        raw =
            (decoded['candidates'] ?? decoded['data'] ?? decoded['items'] ?? [])
                as List<dynamic>;
      } else {
        raw = const [];
      }

      final items = raw
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => e.cast<String, dynamic>())
          .map((e) {
            final name = _mkName(e);
            final party = _mkParty(e);
            final position = _mkPosition(e);
            final photoUrl = _mkPhoto(e, baseUrl);
            final program = (e['program'] ?? e['department'] ?? '').toString();
            final yearSection = (e['year_section'] ?? e['year'] ?? '')
                .toString();
            final organization = (e['organization'] ?? '').toString();
            final partyName = (e['party_name'] ?? '').toString();
            final candidateType = (e['candidate_type'] ?? '').toString();
            final platform = (e['platform'] ?? '').toString();
            return {
              'name': name.trim(),
              'party': (partyName.isNotEmpty ? partyName : party)
                  .toString()
                  .trim(),
              'party_name': partyName,
              'organization': organization.toString().trim(),
              'candidate_type': candidateType,
              'position': position.toString().trim(),
              'program': program.toString().trim(),
              'year_section': yearSection.toString().trim(),
              'platform': platform.toString().trim(),
              'photoUrl': photoUrl,
            };
          })
          .where((m) => (m['name'] as String).isNotEmpty)
          .toList();
      return items;
    } catch (_) {
      return [];
    }
  }

  static String _mkName(Map<String, dynamic> e) {
    final a = (e['name'] ?? e['candidate_name'] ?? e['fullname'] ?? '')
        .toString();
    if (a.isNotEmpty) return a;
    final f = (e['first_name'] ?? e['firstname'] ?? e['given_name'] ?? '')
        .toString();
    final m = (e['middle_name'] ?? e['middlename'] ?? e['mname'] ?? '')
        .toString();
    final l = (e['last_name'] ?? e['lastname'] ?? e['surname'] ?? '')
        .toString();
    return [f, m, l]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _mkParty(Map<String, dynamic> e) {
    return (e['organization'] ??
            e['party'] ??
            e['party_name'] ??
            e['partylist'] ??
            e['party_list'] ??
            '')
        .toString();
  }

  static String _mkPosition(Map<String, dynamic> e) {
    return (e['position'] ?? e['role'] ?? e['seat'] ?? '').toString();
  }

  static String? _mkPhoto(Map<String, dynamic> e, String baseUrl) {
    final direct =
        (e['photo'] ??
        e['image'] ??
        e['profile'] ??
        e['avatar'] ??
        e['img_url'] ??
        e['url']);
    final name = _mkName(e);
    if (direct is String && direct.isNotEmpty) {
      if (direct.startsWith('http')) return direct;
      return '$baseUrl/$direct'
          .replaceAll('//', '/')
          .replaceFirst('http:/', 'http://')
          .replaceFirst('https:/', 'https://');
    }
    final sid = (e['student_id'] ?? e['studentId'] ?? '').toString();
    if (name.isNotEmpty) {
      return '$baseUrl/get_candidate_photo.php?name=' +
          Uri.encodeComponent(name);
    }
    if (sid.isNotEmpty) {
      return '$baseUrl/get_candidate_photo.php?student_id=' +
          Uri.encodeComponent(sid);
    }
    return null;
  }
}
