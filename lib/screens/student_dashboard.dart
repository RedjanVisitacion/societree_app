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
  late DateTime _electionEnd;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  List<Map<String, dynamic>> _parties = const [];
  bool _loadingParties = false;
  final PageController _omniController = PageController(viewportFraction: 1.0);
  Timer? _slideTimer;
  List<String> _omnibusImages = const [];
  int get _omniPageCount => (_omnibusImages.length + 1) ~/ 2; // 2 images per page
  int _omniCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    // Placeholder election end time; adjust as needed from backend/config
    _electionEnd = DateTime.now().add(const Duration(days: 3, hours: 2, minutes: 38, seconds: 12));
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadParties();
    _loadOmnibusImages();
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
    _slideTimer?.cancel();
    _omniController.dispose();
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
        if (_omnibusImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildOmnibusSlideshow(theme),
        ],
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
        const SizedBox(height: 24),
        Text('Things to know', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          children: [
            _infoCard(
              context,
              title: 'Top Manifesto\nHighlights',
              colors: const [Color(0xFFD2B0F6), Color(0xFF9BB4F7)],
              icon: Icons.article_outlined,
            ),
            _infoCard(
              context,
              title: 'FAQs & Voter\nEducation',
              colors: const [Color(0xFFE6B1C0), Color(0xFFD5A7F7)],
              icon: Icons.help_outline,
            ),
            _infoCard(
              context,
              title: 'Find near by\npolling station',
              colors: const [Color(0xFFA6B6F8), Color(0xFFB7A6F9)],
              icon: Icons.location_on_outlined,
            ),
          ],
        ),
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

  Future<void> _loadOmnibusImages() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestContent) as Map<String, dynamic>;
      final images = manifestMap.keys
          .where((k) => k.startsWith('assets/images/omnibus/'))
          .where((k) => k.toLowerCase().endsWith('.png') || k.toLowerCase().endsWith('.jpg') || k.toLowerCase().endsWith('.jpeg') || k.toLowerCase().endsWith('.webp'))
          .toList()
        ..sort();
      if (mounted) {
        setState(() => _omnibusImages = images);
        _startSlideshowTimer();
      }
    } catch (_) {
      if (mounted) setState(() => _omnibusImages = const []);
    }
  }

  void _startSlideshowTimer() {
    _slideTimer?.cancel();
    if (_omniPageCount == 0) return;
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _omniPageCount == 0 || !_omniController.hasClients) return;
      final target = (_omniCurrentPage + 1) % _omniPageCount;
      _omniController.animateToPage(
        target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildOmnibusSlideshow(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 140,
        child: GestureDetector(
          onTap: () {
            final startImageIndex = (_omniCurrentPage * 2).clamp(0, _omnibusImages.isEmpty ? 0 : _omnibusImages.length - 1);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _OmnibusReaderScreen(
                  images: _omnibusImages,
                  initialIndex: startImageIndex,
                ),
              ),
            );
          },
          child: Stack(
          children: [
            PageView.builder(
              controller: _omniController,
              itemCount: _omniPageCount,
              onPageChanged: (i) {
                if (mounted) setState(() => _omniCurrentPage = i);
              },
              itemBuilder: (context, index) {
                final start = index * 2;
                final slice = _omnibusImages.skip(start).take(2).toList();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(2, (i) => i)
                      .map((i) {
                        final hasImage = i < slice.length;
                        return Expanded(
                          child: Container(
                            // No margins or background so images are seamlessly merged horizontally
                            margin: EdgeInsets.zero,
                            color: Colors.transparent,
                            child: hasImage
                                ? Image.asset(
                                    slice[i],
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported)),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      })
                      .toList(),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_omniPageCount, (i) => i)
                    .map((i) {
                      final isActive = (_omniCurrentPage == i);
                      return Container(
                        width: isActive ? 12 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF6E63F6) : Colors.white70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _OmnibusReaderScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _OmnibusReaderScreen({Key? key, required this.images, required this.initialIndex}) : super(key: key);
  @override
  State<_OmnibusReaderScreen> createState() => _OmnibusReaderScreenState();
}

class _OmnibusReaderScreenState extends State<_OmnibusReaderScreen> {
  late final PageController _controller;
  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Omnibus'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final path = widget.images[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
