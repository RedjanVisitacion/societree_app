import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

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
  final List<String> _elecomCandidates = const [
    'Candidate A',
    'Candidate B',
    'Candidate C',
  ];
  late DateTime _electionEnd;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  List<Map<String, dynamic>> _parties = const [];
  bool _loadingParties = false;

  @override
  void initState() {
    super.initState();
    // Placeholder election end time; adjust as needed from backend/config
    _electionEnd = DateTime.now().add(const Duration(days: 3, hours: 2, minutes: 38, seconds: 12));
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadParties();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');
    return Scaffold(
      appBar: isElecom
          ? AppBar(toolbarHeight: 0, elevation: 0)
          : AppBar(
              title: Text(widget.orgName),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
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
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                              height: 90,
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
    );
  }

  Widget _buildElecomDashboard(ThemeData theme) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40),
            Row(children: [
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
            ]),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
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
              Text('Assembly Election', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'General Election to legislative assembly of Tamil Nadu 2024',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Parties & Candidates', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            TextButton(onPressed: () {}, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingParties) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())) else
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: (_parties.isEmpty ? List<Map<String, dynamic>>.generate(6, (i) => {'name': 'Party ${i+1}', 'logoUrl': null}) : _parties)
              .map((p) {
            final logoUrl = p['logoUrl'] as String?;
            final name = (p['name'] ?? '').toString();
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEF8),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: logoUrl != null
                          ? Image.network(
                              logoUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.flag, color: Color(0xFF6E63F6)),
                            )
                          : const Icon(Icons.flag, color: Color(0xFF6E63F6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
