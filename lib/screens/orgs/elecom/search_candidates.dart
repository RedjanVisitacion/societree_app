// ignore_for_file: unused_local_variable, unused_element

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SearchCandidates extends StatefulWidget {
  final List<Map<String, dynamic>> parties;
  final List<Map<String, dynamic>> candidates;
  final bool autofocus;
  const SearchCandidates({super.key, required this.parties, required this.candidates, this.autofocus = false});

  @override
  State<SearchCandidates> createState() => _SearchCandidatesState();
}

class _SearchCandidatesState extends State<SearchCandidates> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _searching = false;
  List<Map<String, dynamic>> _searchResults = const [];

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    final query = q.trim();
    setState(() {
      _searchQuery = query;
      _searching = true;
    });
    if (query.length < 1) {
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
      return;
    }
    final ql = query.toLowerCase();
    final partyResults = widget.parties
        .map((p) => {
              'type': 'party',
              'name': (p['name'] ?? '').toString(),
              'logoUrl': p['logoUrl']
            })
        .where((m) => (m['name'] as String).toLowerCase().contains(ql));
    final candidateResults = widget.candidates
        .map((c) => {
              'type': 'candidate',
              'name': (c['name'] ?? '').toString().trim(),
              'party': (c['party_name'] ?? c['party'] ?? '').toString().trim(),
              'party_name': (c['party_name'] ?? '').toString().trim(),
              'position': (c['position'] ?? '').toString(),
              'organization': (c['organization'] ?? '').toString(),
              'department': (c['program'] ?? c['department'] ?? '').toString(),
              'year_section': (c['year_section'] ?? '').toString(),
              'platform': (c['platform'] ?? '').toString(),
              'candidate_type': (c['candidate_type'] ?? '').toString(),
              'photoUrl': c['photoUrl']
            })
        .where((m) {
      final n = (m['name'] as String).toLowerCase();
      final p = (m['party'] as String).toLowerCase();
      return n.contains(ql) || p.contains(ql);
    });
    final results = [...partyResults, ...candidateResults];
    setState(() {
      _searchResults = results;
      _searching = false;
    });
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

  Future<void> _showSearchResultDetails(BuildContext context, Map<String, dynamic> m) async {
    final isParty = (m['type'] == 'party');
    if (isParty) {
      _showPartyDetails(context, m['name']?.toString() ?? '', m['logoUrl'] as String?);
    } else {
      // Normalize candidate fields to match dashboard details display
      final candidate = {
        'name': (m['name'] ?? '').toString(),
        'organization': (m['organization'] ?? '').toString(),
        'party': (m['party'] ?? '').toString(),
        'party_name': (m['party_name'] ?? '').toString(),
        'position': (m['position'] ?? '').toString(),
        'program': (m['department'] ?? '').toString(),
        'year_section': (m['year_section'] ?? '').toString(),
        'platform': (m['platform'] ?? '').toString(),
        'photoUrl': m['photoUrl'],
      };
      _showCandidateDetails(context, candidate);
    }
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
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white70, size: 56),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPartyDetails(BuildContext context, String partyName, String? logoUrl) {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> partyCandidates = widget.candidates.where((c) {
      final p = (c['party'] ?? c['party_name'] ?? c['organization'] ?? '').toString().trim();
      return p.toLowerCase() == partyName.toLowerCase();
    }).cast<Map<String, dynamic>>().toList();
    int _posIndex(String pos) {
      final order = [
        'President',
        'Vice President',
        'Secretary',
        'Treasurer',
        'Auditor',
        'P.I.O.', 'PIO', 'Public Information Officer',
        'Representative',
      ];
      final i = order.indexWhere((e) => e.toLowerCase() == pos.toLowerCase());
      return i >= 0 ? i : 1000;
    }
    final positions = partyCandidates.map((e) => (e['position'] ?? '').toString()).toSet().toList()
      ..sort((a, b) => _posIndex(a).compareTo(_posIndex(b)));
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        onTap: logoUrl == null ? null : () => _openPhoto(ctx, logoUrl),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF1EEF8),
                          child: ClipOval(
                            child: logoUrl != null
                                ? Image.network(logoUrl, width: 48, height: 48, fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.flag, color: Color(0xFF6E63F6)))
                                : const Icon(Icons.flag, color: Color(0xFF6E63F6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partyName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            Text('${partyCandidates.length} candidate${partyCandidates.length == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
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
                              child: Text(pos, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ],
                          ...partyCandidates
                              .where((c) => (c['position'] ?? '').toString() == pos)
                              .map((c) {
                            final photo = c['photoUrl'] as String?;
                            final nm = (c['name'] ?? '').toString();
                            final prg = (c['program'] ?? '').toString();
                            final ys = (c['year_section'] ?? '').toString();
                            final subtitle = [prg, ys].where((s) => s.isNotEmpty).join(' • ');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEAEAEA),
                                foregroundColor: Colors.grey,
                                backgroundImage: photo != null ? NetworkImage(photo) : null,
                                child: photo == null ? const Icon(Icons.person) : null,
                              ),
                              title: Text(nm, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                              onTap: () => _showCandidateDetails(ctx, c),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                        ],
                        if (partyCandidates.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text('No candidates found', style: theme.textTheme.bodyMedium),
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

  void _showCandidateDetails(BuildContext context, Map<String, dynamic> c) {
    final name = (c['name'] ?? '').toString();
    final org = (c['organization'] ?? c['party'] ?? c['party_name'] ?? '').toString();
    final pos = (c['position'] ?? '').toString();
    final program = (c['program'] ?? '').toString();
    final yearSection = (c['year_section'] ?? '').toString();
    final platform = (c['platform'] ?? '').toString();
    final photo = c['photoUrl'] as String?;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        onTap: photo == null ? null : () => _openPhoto(ctx, photo),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFEAEAEA),
                          foregroundColor: Colors.grey,
                          backgroundImage: photo != null ? NetworkImage(photo) : null,
                          child: photo == null ? const Icon(Icons.person, size: 36) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: th.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            Text(pos, style: th.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
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
                          subtitle: Text(yearSection.isEmpty ? '—' : yearSection),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text('Platform', style: th.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(platform.isEmpty ? '—' : platform, style: th.textTheme.bodyMedium),
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

  Widget _buildSearchResults(ThemeData theme) {
    if (_searching) {
      return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
    }
    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF1EEF8), borderRadius: BorderRadius.circular(12)),
        child: Text('No results for "$_searchQuery"', style: theme.textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = _searchResults[i];
        final type = (m['type'] ?? '').toString();
        final isParty = type == 'party';
        final title = (m['name'] ?? '').toString();
        final subtitle = isParty ? 'Party' : [m['position'], m['party']].where((e) => (e ?? '').toString().isNotEmpty).join(' • ');
        final imageUrl = isParty ? m['logoUrl'] as String? : m['photoUrl'] as String?;
        return Container(
          decoration: BoxDecoration(color: const Color(0xFFF1EEF8), borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: imageUrl != null
                    ? Image.network(imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(isParty ? Icons.flag : Icons.person, color: const Color(0xFF6E63F6)))
                    : Icon(isParty ? Icons.flag : Icons.person, color: const Color(0xFF6E63F6)),
              ),
            ),
            title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(isParty ? 'Party' : 'Candidate', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF6E63F6), fontWeight: FontWeight.w700)),
            ),
            onTap: () async {
              _searchDebounce?.cancel();
              FocusScope.of(context).unfocus();
              setState(() {
                _searchCtrl.clear();
                _searchQuery = '';
                _searchResults = const [];
              });
              await _showSearchResultDetails(context, m);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 300), () {
              _runSearch(v);
            });
          },
          autofocus: widget.autofocus,
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
        const SizedBox(height: 8),
        Expanded(
          child: _searchQuery.isEmpty
              ? const SizedBox.shrink()
              : Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildSearchResults(theme),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
