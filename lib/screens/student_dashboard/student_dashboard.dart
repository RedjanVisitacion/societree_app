// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:societree_app/screens/student_dashboard/services/student_dashboard_service.dart';
import 'package:societree_app/screens/student_dashboard/widgets/student_dashboard_appbar.dart';
import 'package:societree_app/screens/student_dashboard/widgets/student_bottom_nav_bar.dart';
import 'package:societree_app/screens/student_dashboard/widgets/elecom_dashboard_content.dart';
import 'package:societree_app/screens/student_dashboard/widgets/party_details_sheet.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');
    return Scaffold(
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
      bottomNavigationBar: StudentBottomNavBar.build(
        context: context,
        isElecom: isElecom,
        isMenuOpen: _isMenuOpen,
      ),
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
                  physics: const AlwaysScrollableScrollPhysics(),
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
                physics: const AlwaysScrollableScrollPhysics(),
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
