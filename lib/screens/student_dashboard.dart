// ignore_for_file: unused_element

// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:societree_app/screens/orgs/elecom/omnibus_slideshow.dart';
import 'package:societree_app/screens/orgs/elecom/parties_candidates_grid.dart';
import 'package:societree_app/screens/orgs/elecom/things_to_know.dart';
import 'package:societree_app/screens/societree/societree_dashboard.dart';
import 'login_screen.dart';
import 'package:societree_app/config/api_config.dart';

class StudentDashboard extends StatefulWidget {
  final String orgName;
  final String assetPath;
  const StudentDashboard({
    super.key,
    required this.orgName,
    required this.assetPath,
  });

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
  bool _showAllParties = false;
  Timer? _autoCollapseTimer;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    // Placeholder election end time; adjust as needed from backend/config
    _electionEnd = DateTime.now().add(
      const Duration(days: 3, hours: 2, minutes: 38, seconds: 12),
    );
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadParties();
    _loadCandidates();
  }

  void _openPhoto(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.broken_image,
                  color: Colors.white70,
                  size: 56,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCandidateDetails(BuildContext context, Map<String, dynamic> c) {
    final theme = Theme.of(context);
    final name = (c['name'] ?? '').toString();
    final org = (c['organization'] ?? c['party'] ?? c['party_name'] ?? '')
        .toString();
    final pos = (c['position'] ?? '').toString();
    final program = (c['program'] ?? '').toString();
    final yearSection = (c['year_section'] ?? '').toString();
    final platform = (c['platform'] ?? '').toString();
    final photo = c['photoUrl'] as String?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final th = Theme.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: photo == null
                            ? null
                            : () => _openPhoto(context, photo),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFEAEAEA),
                          foregroundColor: Colors.grey,
                          backgroundImage: photo != null
                              ? NetworkImage(photo)
                              : null,
                          child: photo == null
                              ? const Icon(Icons.person, size: 36)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: th.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              pos,
                              style: th.textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.groups_outlined),
                          title: const Text('Organization'),
                          subtitle: Text(org.isEmpty ? '—' : org),
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('Position'),
                          subtitle: Text(pos.isEmpty ? '—' : pos),
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.school_outlined),
                          title: const Text('Department / Program'),
                          subtitle: Text(program.isEmpty ? '—' : program),
                        ),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.class_outlined),
                          title: const Text('Year & Section'),
                          subtitle: Text(
                            yearSection.isEmpty ? '—' : yearSection,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            'Platform',
                            style: th.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            platform.isEmpty ? '—' : platform,
                            style: th.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailLine(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium, softWrap: true),
        ),
      ],
    );
  }

  void _tick() {
    final now = DateTime.now();
    setState(() {
      _remaining = _electionEnd.isAfter(now)
          ? _electionEnd.difference(now)
          : Duration.zero;
    });
  }

  Future<void> _loadParties() async {
    setState(() => _loadingParties = true);
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
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isElecom,
        title: isElecom
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/ELECOM.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/images/img_text/elecom_black.png',
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              )
            : Text(widget.orgName),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),

          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.more_vert),
            offset: const Offset(0, 7),
            position: PopupMenuPosition.under,
            elevation: 4,
            padding: EdgeInsets.zero,
            iconSize: 24,
            color: Theme.of(context).cardColor,
            surfaceTintColor: Colors.transparent,
            constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
            onOpened: () {
              setState(() {
                _isMenuOpen = true;
              });
            },
            onCanceled: () {
              setState(() {
                _isMenuOpen = false;
              });
            },
            onSelected: (value) async {
              setState(() {
                _isMenuOpen = false;
              });
              if (value == 'home') {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SocieTreeDashboard()),
                );
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                );
                if (confirm == true && mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },

            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/Icon-CRCL.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Societree'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.exit_to_app, size: 20),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: isElecom && _isMenuOpen
          ? Stack(
              children: [
                _buildBodyContent(theme, isElecom),
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                ),
              ],
            )
          : _buildBodyContent(theme, isElecom),
      bottomNavigationBar: isElecom
          ? _isMenuOpen
                ? Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 1, thickness: 1),
                          BottomNavigationBar(
                            currentIndex: 0,
                            onTap: (i) {
                              if (i != 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      [
                                        'Home',
                                        'Election',
                                        'Poll History',
                                        'Status',
                                      ][i],
                                    ),
                                  ),
                                );
                              }
                            },
                            type: BottomNavigationBarType.fixed,
                            items: const [
                              BottomNavigationBarItem(
                                icon: Icon(Icons.home_outlined),
                                label: 'Home',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.how_to_vote_outlined),
                                label: 'Election',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.history),
                                label: 'Poll History',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.check),
                                label: 'Status',
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, thickness: 1),
                      BottomNavigationBar(
                        currentIndex: 0,
                        onTap: (i) {
                          if (i != 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  [
                                    'Home',
                                    'Election',
                                    'Poll History',
                                    'Status',
                                  ][i],
                                ),
                              ),
                            );
                          }
                        },
                        type: BottomNavigationBarType.fixed,
                        items: const [
                          BottomNavigationBarItem(
                            icon: Icon(Icons.home_outlined),
                            label: 'Home',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.how_to_vote_outlined),
                            label: 'Election',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.history),
                            label: 'Poll History',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.check),
                            label: 'Status',
                          ),
                        ],
                      ),
                    ],
                  )
          : null,
    );
  }

  Widget _buildBodyContent(ThemeData theme, bool isElecom) {
    return isElecom
        ? Center(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (_showAllParties &&
                    n is ScrollUpdateNotification &&
                    n.metrics.pixels > 0) {
                  _autoCollapseTimer?.cancel();
                  _autoCollapseTimer = Timer(const Duration(seconds: 3), () {
                    if (!mounted) return;
                    setState(() => _showAllParties = false);
                  });
                }
                return false;
              },
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildElecomDashboard(theme),
                  ),
                ),
              ),
            ),
          )
        : Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: const Color(0xFFF0F0F0),
                        child: ClipOval(
                          child: Image.asset(
                            widget.assetPath,
                            width: 90,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.school,
                              size: 56,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.orgName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
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
                  arguments: {
                    'parties': _parties,
                    'candidates': _candidates,
                    'isElecom': isElecom,
                  },
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
            Text(
              'Election Countdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B6CF6),
                    Color(0xFFB07CF3),
                    Color(0xFFE7B56A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'USTP-OROQUIETA Election',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'General Election to legislative assembly',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
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
                    days > 0
                        ? 'You have $days days left to vote. Don\'t miss your chance!'
                        : 'Voting closes soon!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFFFE4E4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E63F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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
                                    filter: ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: AlertDialog(
                                      title: const Text('Confirm Vote'),
                                      content: Text(
                                        _selectedCandidate == null
                                            ? 'Proceed to vote?'
                                            : 'Cast your vote for "${_selectedCandidate!}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                              if (ok == true && mounted) {
                                setState(() => _voted = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vote submitted'),
                                  ),
                                );
                              }
                            },
                      child: const Text('Vote Now'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Omnibus Code',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const OmnibusSlideshow(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parties & Candidates',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_parties.length > 3)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showAllParties = !_showAllParties);
                    },
                    icon: Icon(
                      _showAllParties
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      size: 18,
                    ),
                    label: Text(_showAllParties ? 'See Less' : 'See All'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            PartiesCandidatesGrid(
              parties: _showAllParties
                  ? _parties
                  : (_parties.length > 3
                        ? _parties.take(3).toList()
                        : _parties),
              loading: _loadingParties,
              onPartyTap: (party) => _showPartyDetails(context, party),
            ),
            const SizedBox(height: 24),
            Text(
              'Things to know',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ThingsToKnowGrid(
              onTopManifesto: _openManifestoHighlights,
              onFaqs: _openFaqsEducation,
              onFindPolling: _openFindPollingStation,
            ),
          ],
        ),
        const SizedBox.shrink(),
      ],
    );
  }

  void _showPartyDetails(BuildContext context, Map<String, dynamic> party) {
    final name = (party['name'] ?? '').toString();
    final logoUrl = party['logoUrl'] as String?;
    List<Map<String, dynamic>> partyCandidates = _candidates
        .where((c) {
          final p = (c['party'] ?? c['party_name'] ?? c['organization'] ?? '')
              .toString()
              .trim();
          return p.toLowerCase() == name.toLowerCase();
        })
        .cast<Map<String, dynamic>>()
        .toList();
    int _posIndex(String pos) {
      final order = [
        'President',
        'Vice President',
        'Secretary',
        'Treasurer',
        'Auditor',
        'P.I.O.',
        'PIO',
        'Public Information Officer',
        'Representative',
      ];
      final i = order.indexWhere((e) => e.toLowerCase() == pos.toLowerCase());
      return i >= 0 ? i : 1000;
    }

    final positions =
        partyCandidates
            .map((e) => (e['position'] ?? '').toString())
            .toSet()
            .toList()
          ..sort((a, b) => _posIndex(a).compareTo(_posIndex(b)));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: logoUrl == null
                            ? null
                            : () => _openPhoto(context, logoUrl),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF1EEF8),
                          child: ClipOval(
                            child: logoUrl != null
                                ? Image.network(
                                    logoUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.flag,
                                      color: Color(0xFF6E63F6),
                                    ),
                                  )
                                : const Icon(
                                    Icons.flag,
                                    color: Color(0xFF6E63F6),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${partyCandidates.length} candidate${partyCandidates.length == 1 ? '' : 's'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        for (final pos in positions) ...[
                          if (pos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                pos,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          ...partyCandidates
                              .where(
                                (c) => (c['position'] ?? '').toString() == pos,
                              )
                              .map((c) {
                                final photo = c['photoUrl'] as String?;
                                final nm = (c['name'] ?? '').toString();
                                final prg = (c['program'] ?? '').toString();
                                final ys = (c['year_section'] ?? '').toString();
                                final subtitle = [
                                  prg,
                                  ys,
                                ].where((s) => s.isNotEmpty).join(' • ');
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFEAEAEA),
                                    foregroundColor: Colors.grey,
                                    backgroundImage: photo != null
                                        ? NetworkImage(photo)
                                        : null,
                                    child: photo == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(
                                    nm,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: subtitle.isNotEmpty
                                      ? Text(subtitle)
                                      : null,
                                  onTap: () =>
                                      _showCandidateDetails(context, c),
                                );
                              })
                              .toList(),
                          const SizedBox(height: 8),
                        ],
                        if (partyCandidates.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No candidates found',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openManifestoHighlights() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voting Guidelines',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: const [
                      ListTile(
                        leading: Icon(Icons.verified_user_outlined),
                        title: Text('Bring your valid student ID'),
                      ),
                      ListTile(
                        leading: Icon(Icons.schedule_outlined),
                        title: Text('Follow the official election schedule'),
                      ),
                      ListTile(
                        leading: Icon(Icons.public_outlined),
                        title: Text('Use the official voting portal only'),
                      ),
                      ListTile(
                        leading: Icon(Icons.how_to_vote_outlined),
                        title: Text('Cast one vote per position'),
                      ),
                      ListTile(
                        leading: Icon(Icons.fact_check_outlined),
                        title: Text('Review your ballot before submitting'),
                      ),
                      ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Wait for the confirmation message'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFaqsEducation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Election FAQs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: const [
                      ListTile(
                        title: Text('Who can vote?'),
                        subtitle: Text(
                          'All currently enrolled students with valid IDs.',
                        ),
                      ),
                      ListTile(
                        title: Text('Where do I vote?'),
                        subtitle: Text(
                          'Inside campus via the official Societree app.',
                        ),
                      ),
                      ListTile(
                        title: Text('Forgot password?'),
                        subtitle: Text(
                          'Contact ELECOM at the help desk to reset your access.',
                        ),
                      ),
                      ListTile(
                        title: Text('Is my vote confidential?'),
                        subtitle: Text(
                          'Yes. Votes are anonymized and secured by ELECOM.',
                        ),
                      ),
                      ListTile(
                        title: Text('Internet needed?'),
                        subtitle: Text(
                          'Yes, connect to campus Wi‑Fi or mobile data inside campus.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFindPollingStation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus polling stations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: const [
                      ListTile(
                        leading: Icon(Icons.location_on_outlined),
                        title: Text('Main Hall – Booth A'),
                        subtitle: Text('Open 8:00 AM – 5:00 PM'),
                      ),
                      ListTile(
                        leading: Icon(Icons.location_on_outlined),
                        title: Text('Library Lobby – Booth B'),
                        subtitle: Text('Open 8:00 AM – 5:00 PM'),
                      ),
                      ListTile(
                        leading: Icon(Icons.location_on_outlined),
                        title: Text('Engineering Building – Booth C'),
                        subtitle: Text('Open 8:00 AM – 5:00 PM'),
                      ),
                      ListTile(
                        leading: Icon(Icons.support_agent_outlined),
                        title: Text('ELECOM Help Desk'),
                        subtitle: Text(
                          'For assistance and verification concerns',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required List<Color> colors,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
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
      final baseUrl = apiBaseUrl;
      final uri = Uri.parse('$baseUrl/get_candidates.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
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
      String _mkName(Map<String, dynamic> e) {
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

      String _mkParty(Map<String, dynamic> e) {
        // In your DB, organization corresponds to party
        return (e['organization'] ??
                e['party'] ??
                e['party_name'] ??
                e['partylist'] ??
                e['party_list'] ??
                '')
            .toString();
      }

      String _mkPosition(Map<String, dynamic> e) {
        return (e['position'] ?? e['role'] ?? e['seat'] ?? '').toString();
      }

      String? _mkPhoto(Map<String, dynamic> e) {
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

      final items = raw
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => e.cast<String, dynamic>())
          .map((e) {
            final name = _mkName(e);
            final party = _mkParty(e);
            final position = _mkPosition(e);
            final photoUrl = _mkPhoto(e);
            final program = (e['program'] ?? e['department'] ?? '').toString();
            final yearSection = (e['year_section'] ?? e['year'] ?? '')
                .toString();
            final organization = (e['organization'] ?? '').toString();
            final partyName = (e['party_name'] ?? '').toString();
            final candidateType = (e['candidate_type'] ?? '').toString();
            final platform = (e['platform'] ?? '').toString();
            return {
              'name': name.trim(),
              // Political party is strictly the party_name column when present
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
      if (mounted) setState(() => _candidates = items);
    } catch (_) {
      if (mounted) setState(() => _candidates = const []);
    }
  }
}
