import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'package:societree_app/widgets/election_countdown.dart';
import 'package:societree_app/widgets/omnibus_slideshow.dart';
import 'package:societree_app/widgets/parties_candidates_grid.dart';
import 'package:societree_app/widgets/things_to_know.dart';
import 'package:societree_app/widgets/search_candidates.dart';

class StudentDashboard extends StatefulWidget {
  final String orgName;
  final String assetPath;
  const StudentDashboard({super.key, required this.orgName, required this.assetPath});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String? _selectedCandidate;
  bool _voted = false;
  late DateTime _electionEnd;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  List<Map<String, dynamic>> _parties = const [];
  bool _loadingParties = false;
  // Omnibus slideshow handled via external widget now
  List<Map<String, dynamic>> _candidates = const [];

  @override
  void initState() {
    super.initState();
    // Placeholder election end time; adjust as needed from backend/config
    _electionEnd = DateTime.now().add(const Duration(days: 3, hours: 2, minutes: 38, seconds: 12));
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadParties();
    _loadCandidates();
  }

  Widget _detailLine(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  void _tick() {
    final now = DateTime.now();
    setState(() {
      _remaining = _electionEnd.isAfter(now) ? _electionEnd.difference(now) : Duration.zero;
    });
  }

  Future<void> _loadParties() async {
    setState(() => _loadingParties = true);
    try {
      final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.137.1/societree_api');
      final uri = Uri.parse('$baseUrl/get_parties.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final List<dynamic> raw = body['parties'] ?? [];
        final items = raw.map<Map<String, dynamic>>((e) {
          final name = (e['party_name'] ?? '').toString();
          final hasLogo = e['has_logo'] == true || e['has_logo'] == 1;
          final logoUrl = hasLogo
              ? '$baseUrl/get_party_logo.php?name=' + Uri.encodeComponent(name)
              : null;
          return {'name': name, 'logoUrl': logoUrl};
        }).toList();
        if (mounted) setState(() => _parties = items);
      }
    } catch (_) {
      // ignore network errors; keep placeholders
    } finally {
      if (mounted) setState(() => _loadingParties = false);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // Omnibus slideshow lifecycle handled in external widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orgName),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline)),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (ctx) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Logout')),
                      ],
                    ),
                  );
                },
              );
              if (ok == true) {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, isElecom ? 0 : 12, 16, 16),
              child: isElecom
                  ? _buildElecomDashboard(theme)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFF0F0F0),
                          child: ClipOval(
                            child: Image.asset(
                              widget.assetPath,
                              width: 90,
                              // height: 90,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.school, size: 56, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(widget.orgName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Text(
                          'Details for ${widget.orgName} will appear here.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          // Placeholder handlers; wire up as needed
          if (i != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(['Home', 'Election', 'Poll History', 'Status'][i])),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote_outlined), label: 'Election'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Poll History'),
          BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Status'),
        ],
      ),
    );
  }

  Widget _buildElecomDashboard(ThemeData theme) {
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');
    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    Widget timePill(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/search',
                  arguments: {'parties': _parties, 'candidates': _candidates, 'isElecom': isElecom},
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Party/candidates',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF1EEF8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Election Countdown', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B6CF6), Color(0xFFB07CF3), Color(0xFFE7B56A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/ELECOM.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.how_to_vote, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('USTP-OROQUIETA Election', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              'General Election to legislative assembly',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      timePill(days.toString().padLeft(2, '0'), 'days'),
                      const SizedBox(width: 8),
                      timePill(hours.toString().padLeft(2, '0'), 'hours'),
                      const SizedBox(width: 8),
                      timePill(minutes.toString().padLeft(2, '0'), 'mins'),
                      const SizedBox(width: 8),
                      timePill(seconds.toString().padLeft(2, '0'), 'sec'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    days > 0 ? 'You have $days days left to vote. Don\'t miss your chance!' : 'Voting closes soon!',
                    style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFFFE4E4)),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E63F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: _voted
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                barrierDismissible: true,
                                builder: (ctx) {
                                  return BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                    child: AlertDialog(
                                      title: const Text('Confirm Vote'),
                                      content: Text(_selectedCandidate == null
                                          ? 'Proceed to vote?'
                                          : 'Cast your vote for "${_selectedCandidate!}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
                                      ],
                                    ),
                                  );
                                },
                              );
                              if (ok == true && mounted) {
                                setState(() => _voted = true);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vote submitted')));
                              }
                            },
                      child: const Text('Vote Now'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const OmnibusSlideshow(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Parties & Candidates', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('See All'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PartiesCandidatesGrid(parties: _parties, loading: _loadingParties),
            const SizedBox(height: 24),
            Text('Things to know', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const ThingsToKnowGrid(),
          ],
        ),
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _infoCard(BuildContext context, {required String title, required List<Color> colors, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Future<void> _loadCandidates() async {
    try {
      final baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.137.1/societree_api');
      final uri = Uri.parse('$baseUrl/get_candidates.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      List<dynamic> raw;
      if (decoded is List) {
        raw = decoded;
      } else if (decoded is Map<String, dynamic>) {
        raw = (decoded['candidates'] ?? decoded['data'] ?? decoded['items'] ?? []) as List<dynamic>;
      } else {
        raw = const [];
      }
      String _mkName(Map<String, dynamic> e) {
        final a = (e['name'] ?? e['candidate_name'] ?? e['fullname'] ?? '').toString();
        if (a.isNotEmpty) return a;
        final f = (e['first_name'] ?? e['firstname'] ?? e['given_name'] ?? '').toString();
        final m = (e['middle_name'] ?? e['middlename'] ?? e['mname'] ?? '').toString();
        final l = (e['last_name'] ?? e['lastname'] ?? e['surname'] ?? '').toString();
        return [f, m, l].where((s) => s.isNotEmpty).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      }
      String _mkParty(Map<String, dynamic> e) {
        // In your DB, organization corresponds to party
        return (e['organization'] ?? e['party'] ?? e['party_name'] ?? e['partylist'] ?? e['party_list'] ?? '').toString();
      }
      String _mkPosition(Map<String, dynamic> e) {
        return (e['position'] ?? e['role'] ?? e['seat'] ?? '').toString();
      }
      String? _mkPhoto(Map<String, dynamic> e) {
        final direct = (e['photo'] ?? e['image'] ?? e['profile'] ?? e['avatar'] ?? e['img_url'] ?? e['url']);
        final name = _mkName(e);
        if (direct is String && direct.isNotEmpty) {
          if (direct.startsWith('http')) return direct;
          return '$baseUrl/$direct'.replaceAll('//', '/').replaceFirst('http:/', 'http://').replaceFirst('https:/', 'https://');
        }
        final sid = (e['student_id'] ?? e['studentId'] ?? '').toString();
        if (name.isNotEmpty) {
          return '$baseUrl/get_candidate_photo.php?name=' + Uri.encodeComponent(name);
        }
        if (sid.isNotEmpty) {
          return '$baseUrl/get_candidate_photo.php?student_id=' + Uri.encodeComponent(sid);
        }
        return null;
      }
      final items = raw.whereType<Map>()
          .map<Map<String, dynamic>>((e) => e.cast<String, dynamic>())
          .map((e) {
        final name = _mkName(e);
        final party = _mkParty(e);
        final position = _mkPosition(e);
        final photoUrl = _mkPhoto(e);
        final program = (e['program'] ?? e['department'] ?? '').toString();
        final yearSection = (e['year_section'] ?? e['year'] ?? '').toString();
        final organization = (e['organization'] ?? '').toString();
        final partyName = (e['party_name'] ?? '').toString();
        final candidateType = (e['candidate_type'] ?? '').toString();
        final platform = (e['platform'] ?? '').toString();
        return {
          'name': name.trim(),
          // Political party is strictly the party_name column when present
          'party': (partyName.isNotEmpty ? partyName : party).toString().trim(),
          'party_name': partyName,
          'organization': organization.toString().trim(),
          'candidate_type': candidateType,
          'position': position.toString().trim(),
          'program': program.toString().trim(),
          'year_section': yearSection.toString().trim(),
          'platform': platform.toString().trim(),
          'photoUrl': photoUrl
        };
      }).where((m) => (m['name'] as String).isNotEmpty).toList();
      if (mounted) setState(() => _candidates = items);
    } catch (_) {
      if (mounted) setState(() => _candidates = const []);
    }
  }

  
}
