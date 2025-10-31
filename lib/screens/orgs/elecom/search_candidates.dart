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
    final theme = Theme.of(context);
    final isParty = (m['type'] == 'party');
    final title = (m['name'] ?? '').toString();
    final subtitle = isParty
        ? 'Party'
        : [m['position'], m['organization']]
            .map((e) => (e ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .join(' • ');
    final imageUrl = isParty ? m['logoUrl'] as String? : m['photoUrl'] as String?;
    final partyName = (m['party'] ?? m['party_name'] ?? '').toString().trim();
    final department = (m['department'] ?? '').toString();
    final platform = (m['platform'] ?? '').toString();
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Material(
                  color: Theme.of(ctx).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
                      top: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFF1EEF8),
                              child: ClipOval(
                                child: imageUrl != null
                                    ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(isParty ? Icons.flag : Icons.person, color: const Color(0xFF6E63F6)))
                                    : Icon(isParty ? Icons.flag : Icons.person, color: const Color(0xFF6E63F6)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(subtitle, style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!isParty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailLine(theme, 'Political party:', partyName.isNotEmpty ? partyName : 'Independent candidate (no political party)'),
                              const SizedBox(height: 8),
                              if (department.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _detailLine(theme, 'Department:', department),
                              ],
                              if (platform.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _detailLine(theme, 'Platform:', platform),
                              ],
                            ],
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF7F5FF), borderRadius: BorderRadius.circular(12)),
                            child: Text('Party: ${m['name']}', style: theme.textTheme.bodyMedium),
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        final offset = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return SlideTransition(position: offset, child: FadeTransition(opacity: anim, child: child));
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
