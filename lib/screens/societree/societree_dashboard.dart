import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:societree_app/screens/login_screen.dart';
import 'package:societree_app/screens/student_dashboard.dart';

class SocieTreeDashboard extends StatefulWidget {
  const SocieTreeDashboard({super.key});

  @override
  State<SocieTreeDashboard> createState() => _SocieTreeDashboardState();
}

class _SocieTreeDashboardState extends State<SocieTreeDashboard> {
  late final PageController _pageCtrl;
  Timer? _autoTimer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final total = _bannerAssets.length;
      if (total == 0) return;
      _current = (_current + 1) % total;
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          _current,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  List<String> get _bannerAssets => const [
        'assets/images/USG.png',
        'assets/images/ARCU.png',
        'assets/images/ELECOM.png',
        'assets/images/SITE.png',
        'assets/images/PAFE.png',
        'assets/images/AFPROTECH.png',
        'assets/images/ACCESS.png',
        'assets/images/REDCROSS.png',
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = const Color.fromARGB(115, 89, 98, 105);

    final orgs = <_OrgItem>[
      _OrgItem('USG', 'assets/images/USG.png'),
      _OrgItem('ARCU', 'assets/images/ARCU.png'),
      _OrgItem('ELECOM', 'assets/images/ELECOM.png'),
      _OrgItem('SITE', 'assets/images/SITE.png'),
      _OrgItem('PAFE', 'assets/images/PAFE.png'),
      _OrgItem('AFPROTECHS', 'assets/images/AFPROTECH.png'),
      _OrgItem('ACCESS', 'assets/images/ACCESS.png'),
      _OrgItem('RED COSS', 'assets/images/REDCROSS.png'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Icon-NOBG.png',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.park, size: 20, color: Colors.green),
            ),
            const SizedBox(width: 8),
            const Text('SocieTree'),
          ],
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About card with slideshow
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 160,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: PageView.builder(
                                    controller: _pageCtrl,
                                    itemCount: _bannerAssets.length,
                                    onPageChanged: (i) => setState(() => _current = i),
                                    itemBuilder: (context, index) {
                                      final path = _bannerAssets[index];
                                      return Container(
                                        color: Colors.grey.shade100,
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          path,
                                          height: 120,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  child: Row(
                                    children: List.generate(_bannerAssets.length, (i) {
                                      final active = i == _current;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(horizontal: 3),
                                        height: 6,
                                        width: active ? 14 : 6,
                                        decoration: BoxDecoration(
                                          color: active ? Colors.black54 : Colors.black26,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('About', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            'SocieTree is an innovative digital ecosystem at the University of Science and Technology of Southern Philippines (USTP) that unites and empowers the diverse student organizations across campus. Acting as both a technological platform and community hub, SocieTREE facilitates seamless collaboration, enhances student engagement, and nurtures the next generation of leaders through integrated digital solutions.\n\nAs the central nexus for USTP\'s vibrant organizational landscape, SocieTREE cultivates a culture of excellence, innovation, and civic responsibility. The platform supports a thriving network of student groups, including:',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Organizations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: orgs.length,
                        itemBuilder: (context, index) {
                          final it = orgs[index];
                          return _OrgCard(item: it, onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentDashboard(orgName: it.name, assetPath: it.assetPath),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrgItem {
  final String name;
  final String assetPath;
  const _OrgItem(this.name, this.assetPath);
}

class _OrgCard extends StatelessWidget {
  final _OrgItem item;
  final VoidCallback onTap;
  const _OrgCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(60, 89, 98, 105), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFF0F0F0),
              child: ClipOval(
                child: Image.asset(
                  item.assetPath,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.school, size: 28, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
