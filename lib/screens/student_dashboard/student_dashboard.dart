// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:async';
import 'dart:ui';
import 'package:societree_app/screens/student_dashboard/services/student_dashboard_service.dart';
import 'package:societree_app/screens/student_dashboard/widgets/student_dashboard_appbar.dart';
import 'package:societree_app/screens/student_dashboard/widgets/student_bottom_nav_bar.dart';
import 'package:societree_app/screens/student_dashboard/widgets/elecom_dashboard_content.dart';
import 'package:societree_app/screens/student_dashboard/widgets/party_details_sheet.dart';
import 'package:societree_app/main.dart';

/// Custom scroll physics for smooth momentum scrolling similar to Facebook
class SmoothMomentumScrollPhysics extends ClampingScrollPhysics {
  const SmoothMomentumScrollPhysics({super.parent});

  @override
  SmoothMomentumScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothMomentumScrollPhysics(parent: buildParent(ancestor));
  }

  // Custom velocity calculation for better momentum feel
  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  // Override to provide smoother deceleration with better momentum
  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = this.tolerance;

    // If velocity is very small, stop immediately
    if (velocity.abs() < tolerance.velocity) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Handle out of bounds with spring simulation
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Calculate distance to boundaries
    final double outOfBoundsExtent = velocity > 0
        ? position.maxScrollExtent - position.pixels
        : position.minScrollExtent - position.pixels;

    // If we're very close to the edge, use spring simulation for smooth clamping
    if (outOfBoundsExtent.abs() < tolerance.distance * 2) {
      return super.createBallisticSimulation(position, velocity);
    }

    // For in-bounds scrolling, use friction simulation for smoother momentum
    // Lower friction constant = longer momentum scrolling (like Facebook)
    final double friction =
        0.015; // Very low friction for smooth, long momentum

    // Estimate where friction simulation would end (when velocity becomes very small)
    // Friction simulation: v(t) = v0 * e^(-friction * t)
    // When v(t) ≈ 0, we can estimate the distance traveled
    final double estimatedDistance = velocity.abs() / friction;
    final double estimatedEndPosition =
        position.pixels +
        (velocity > 0 ? estimatedDistance : -estimatedDistance);

    // If estimated position would go significantly out of bounds, use spring simulation
    if (estimatedEndPosition < position.minScrollExtent - tolerance.distance ||
        estimatedEndPosition > position.maxScrollExtent + tolerance.distance) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Otherwise use friction for smooth momentum scrolling
    return FrictionSimulation(
      friction,
      position.pixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

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
  List<Map<String, dynamic>> _candidates = const [];
  bool _showAllParties = false;
  Timer? _autoCollapseTimer;
  bool _isMenuOpen = false;
  bool _isBottomBarVisible = true;
  ScrollController? _scrollController;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _electionEnd = DateTime.now().add(
      const Duration(days: 3, hours: 2, minutes: 38, seconds: 12),
    );
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _loadParties();
    _loadCandidates();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final currentOffset = _scrollController!.offset;
    const threshold =
        10.0; // Minimum scroll distance to trigger visibility change

    // Always show bottom bar when at the top
    if (currentOffset <= 0) {
      if (!_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
      _lastScrollOffset = currentOffset;
      return;
    }

    final scrollDelta = currentOffset - _lastScrollOffset;

    // Only update if scroll delta exceeds threshold
    if (scrollDelta.abs() > threshold) {
      if (scrollDelta > 0 && _isBottomBarVisible) {
        // Scrolling down - hide bottom bar
        setState(() {
          _isBottomBarVisible = false;
        });
      } else if (scrollDelta < 0 && !_isBottomBarVisible) {
        // Scrolling up - show bottom bar
        setState(() {
          _isBottomBarVisible = true;
        });
      }
      _lastScrollOffset = currentOffset;
    }
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
      final items = await StudentDashboardService.loadParties();
      if (mounted) setState(() => _parties = items);
    } finally {
      if (mounted) setState(() => _loadingParties = false);
    }
  }

  Future<void> _loadCandidates() async {
    try {
      final items = await StudentDashboardService.loadCandidates();
      if (mounted) setState(() => _candidates = items);
    } catch (_) {
      if (mounted) setState(() => _candidates = const []);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadParties(), _loadCandidates()]);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoCollapseTimer?.cancel();
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');

    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        // Only apply dark theme to ELECOM student dashboard
        final shouldUseDarkMode = isElecom && themeNotifier.isDarkMode;
        final dashboardTheme = shouldUseDarkMode
            ? ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              )
            : Theme.of(context);

        return Theme(
          data: dashboardTheme,
          child: Scaffold(
            appBar: StudentDashboardAppBar.build(
              context: context,
              orgName: widget.orgName,
              isElecom: isElecom,
              onMenuStateChanged: (isOpen) {
                setState(() => _isMenuOpen = isOpen);
              },
            ),
            body: isElecom && _isMenuOpen
                ? Stack(
                    children: [
                      Builder(
                        builder: (context) =>
                            _buildBodyContent(Theme.of(context), isElecom),
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
                : Builder(
                    builder: (context) =>
                        _buildBodyContent(Theme.of(context), isElecom),
                  ),
            bottomNavigationBar: StudentBottomNavBar.build(
              context: context,
              isElecom: isElecom,
              isMenuOpen: _isMenuOpen,
              isVisible: _isBottomBarVisible,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyContent(ThemeData theme, bool isElecom) {
    return isElecom
        ? Center(
            child: RefreshIndicator(
              onRefresh: _refreshData,
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
                  controller: _scrollController,
                  physics: const SmoothMomentumScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ElecomDashboardContent(
                        theme: theme,
                        remaining: _remaining,
                        voted: _voted,
                        selectedCandidate: _selectedCandidate,
                        parties: _parties,
                        loadingParties: _loadingParties,
                        showAllParties: _showAllParties,
                        candidates: _candidates,
                        onToggleShowAllParties: (value) {
                          setState(() => _showAllParties = value);
                        },
                        onVoteSubmitted: (value) {
                          setState(() => _voted = value);
                        },
                        onShowPartyDetails: (party) {
                          showPartyDetails(context, party, _candidates);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : Center(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const SmoothMomentumScrollPhysics(),
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
            ),
          );
  }
}
