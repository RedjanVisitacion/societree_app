import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:societree_app/config/api_config.dart';
import 'package:societree_app/services/api_service.dart';
import 'package:societree_app/screens/elecom_admin/candidate_edit_screen.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final ApiService _api = ApiService(baseUrl: apiBaseUrl);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _candidates = [];
  String _query = '';
  final Set<int> _selectedIds = <int>{};
  bool _selectionMode = false;
  // Party metadata fetched from API
  final Map<String, bool> _partyHasLogo = <String, bool>{};
  final Map<String, String> _partyLogoUrl = <String, String>{};

  // Desired position order within each party
  static const List<String> _positionOrder = <String>[
    'President',
    'Vice President',
    'General Secretary',
    'Associate Secretary',
    'Treasurer',
    'Auditor',
    'Public Information Officer',
    'BSIT Representative',
    'BTLED Representative',
    'BFPT Representative',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _areAllVisibleSelected() {
    final ids = _filtered.map((e) => e['id']).whereType<int>();
    if (ids.isEmpty) return false;
    for (final id in ids) {
      if (!_selectedIds.contains(id)) return false;
    }
    return true;
  }

  void _toggleSelectAllVisible(bool select) {
    setState(() {
      final ids = _filtered.map((e) => e['id']).whereType<int>();
      for (final id in ids) {
        if (select) {
          _selectedIds.add(id);
        } else {
          _selectedIds.remove(id);
        }
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedIds.clear();
    });
    try {
      final res = await _api.getCandidates();
      final resParties = await _api.getParties();
      if (resParties['success'] == true && resParties['parties'] != null) {
        _partyHasLogo.clear();
        _partyLogoUrl.clear();
        for (final p in List<Map<String, dynamic>>.from(resParties['parties'])) {
          final name = (p['party_name'] ?? '').toString();
          if (name.isEmpty) continue;
          _partyHasLogo[name] = p['has_logo'] == true;
          // Prefer constructing the dynamic logo endpoint used by the student dashboard
          if (_partyHasLogo[name] == true) {
            _partyLogoUrl[name] = apiBaseUrl + '/get_party_logo.php?name=' + Uri.encodeComponent(name);
          } else {
            final url = p['logo_url'];
            if (url is String && url.isNotEmpty) _partyLogoUrl[name] = url;
          }
        }
      }
      if (res['success'] == true && res['candidates'] != null) {
        final list = List<Map<String, dynamic>>.from(res['candidates']);
        setState(() {
          _candidates = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load candidates';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  // Filtering by search query
  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _candidates;
    final q = _query.toLowerCase();
    return _candidates.where((c) {
      final first = (c['first_name'] ?? '').toString().toLowerCase();
      final middle = (c['middle_name'] ?? '').toString().toLowerCase();
      final last = (c['last_name'] ?? '').toString().toLowerCase();
      final id = (c['student_id'] ?? '').toString().toLowerCase();
      final party = (c['party_name'] ?? '').toString().toLowerCase();
      final pos = (c['position'] ?? '').toString().toLowerCase();
      final name = '$first $middle $last';
      return name.contains(q) || id.contains(q) || party.contains(q) || pos.contains(q);
    }).toList();
  }

  // Build: Map party -> candidates grouped and sorted by position order then name
  Map<String, List<Map<String, dynamic>>> get _byParty {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final c in _filtered) {
      final party = (c['party_name'] ?? 'Independent').toString();
      map.putIfAbsent(party, () => <Map<String, dynamic>>[]).add(c);
    }
    // sort each party's list by position order then name
    for (final entry in map.entries) {
      entry.value.sort((a, b) {
        final pa = (a['position'] ?? '').toString();
        final pb = (b['position'] ?? '').toString();
        int ia = _positionOrder.indexOf(pa);
        int ib = _positionOrder.indexOf(pb);
        ia = ia == -1 ? 999 : ia;
        ib = ib == -1 ? 999 : ib;
        if (ia != ib) return ia.compareTo(ib);
        final na = ('${a['first_name'] ?? ''} ${a['middle_name'] ?? ''} ${a['last_name'] ?? ''}').trim();
        final nb = ('${b['first_name'] ?? ''} ${b['middle_name'] ?? ''} ${b['last_name'] ?? ''}').trim();
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });
    }
    // Ensure deterministic party order: put non-empty parties A-Z, then Independent at end
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a == 'Independent' && b != 'Independent') return 1;
        if (b == 'Independent' && a != 'Independent') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return {for (final k in keys) k: map[k]!};
  }

  bool _isPartyFullySelected(String party, List<Map<String, dynamic>> list) {
    for (final c in list) {
      final id = c['id'];
      if (id is int) {
        if (!_selectedIds.contains(id)) return false;
      }
    }
    return list.isNotEmpty;
  }

  void _togglePartySelection(String party, List<Map<String, dynamic>> list, bool select) {
    setState(() {
      for (final c in list) {
        final id = c['id'];
        if (id is int) {
          if (select) {
            _selectedIds.add(id);
          } else {
            _selectedIds.remove(id);
          }
        }
      }
    });
  }

  Future<void> _unregisterSelected() async {
    if (_selectedIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Unregister Candidates'),
        content: Text('Unregister ${_selectedIds.length} selected candidate(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Unregister')),
        ],
      ),
    );
    if (ok != true) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unregistering...')));
    try {
      for (final id in _selectedIds.toList()) {
        await _api.deleteCandidate(candidateId: id);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected candidates unregistered')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to unregister some candidates')));
      }
    }
  }

  Future<void> _unregisterParty(String party) async {
    if (party == 'Independent') return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Unregister Party'),
        content: Text('Unregister entire party "$party" and all of its candidates?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unregister Party'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await _api.deleteParty(partyName: party);
    final success = res['success'] == true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Party unregistered' : (res['message'] ?? 'Failed to unregister party').toString()),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
    if (success) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final parties = _byParty;

    String _initialsFor(Map<String, dynamic> c) {
      final f = (c['first_name'] ?? '').toString();
      final m = (c['middle_name'] ?? '').toString();
      final l = (c['last_name'] ?? '').toString();
      String ini = '';
      if (f.isNotEmpty) ini += f[0];
      if (l.isNotEmpty) ini += l[0];
      if (ini.isEmpty && m.isNotEmpty) ini += m[0];
      return ini.toUpperCase();
    }

    String? _photoUrlFor(Map<String, dynamic> e) {
      final first = (e['first_name'] ?? '').toString();
      final middle = (e['middle_name'] ?? '').toString();
      final last = (e['last_name'] ?? '').toString();
      final name = [first, middle, last].where((s) => s.isNotEmpty).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      final sid = (e['student_id'] ?? e['studentId'] ?? '').toString();
      final cb = DateTime.now().millisecondsSinceEpoch.toString();
      if (sid.isNotEmpty) {
        return apiBaseUrl + '/get_candidate_photo.php?student_id=' + Uri.encodeComponent(sid) + '&cb=' + cb;
      }
      if (name.isNotEmpty) {
        return apiBaseUrl + '/get_candidate_photo.php?name=' + Uri.encodeComponent(name) + '&cb=' + cb;
      }
      return null;
    }

    Future<void> _openImage(String url, {String? title}) async {
      if (url.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => _FullScreenImageViewer(url: url, title: title),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidates'),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              tooltip: _areAllVisibleSelected() ? 'Clear All' : 'Select All',
              onPressed: _loading
                  ? null
                  : () {
                      final all = _areAllVisibleSelected();
                      _toggleSelectAllVisible(!all);
                    },
              icon: const Icon(Icons.select_all),
            ),
            IconButton(
              tooltip: 'Unregister Selected',
              onPressed: _selectedIds.isEmpty || _loading ? null : _unregisterSelected,
              icon: const Icon(Icons.person_remove),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _selectionMode = false;
                        _selectedIds.clear();
                      }),
              icon: const Icon(Icons.close),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Unregister',
              onPressed: _loading
                  ? null
                  : () => setState(() {
                        _selectionMode = true;
                      }),
              icon: const Icon(Icons.person_remove),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search name, ID, party, position... ',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : parties.isEmpty
                        ? const Center(child: Text('No candidates'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              children: parties.entries.map((entry) {
                                final party = entry.key;
                                final list = entry.value;
                                final allSelected = _isPartyFullySelected(party, list);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            if (_selectionMode)
                                              Checkbox(
                                                value: allSelected,
                                                onChanged: (v) => _togglePartySelection(party, list, (v ?? false)),
                                              ),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: (_partyLogoUrl[party] != null)
                                                  ? () => _openImage(_partyLogoUrl[party]!, title: party)
                                                  : null,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                                                ),
                                                child: CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: Colors.white,
                                                  child: ClipOval(
                                                    child: _partyLogoUrl[party] != null
                                                        ? Image.network(
                                                            _partyLogoUrl[party]!,
                                                            width: 36,
                                                            height: 36,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (c, e, s) => Icon(
                                                              _partyHasLogo[party] == true ? Icons.flag : Icons.flag_outlined,
                                                              size: 18,
                                                              color: Theme.of(context).colorScheme.primary,
                                                            ),
                                                          )
                                                        : Icon(
                                                            _partyHasLogo[party] == true ? Icons.flag : Icons.flag_outlined,
                                                            size: 22,
                                                            color: Theme.of(context).colorScheme.primary,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                party,
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                            ),
                                            if (party != 'Independent')
                                              IconButton(
                                                tooltip: 'Unregister Party',
                                                onPressed: () => _unregisterParty(party),
                                                icon: const Icon(Icons.group_remove, color: Colors.red),
                                              ),
                                          ],
                                        ),
                                        const Divider(height: 8),
                                        ...list.map((c) {
                                          final id = c['id'] as int?;
                                          final pos = (c['position'] ?? '').toString();
                                          final name = ('${c['first_name'] ?? ''} ${c['middle_name'] ?? ''} ${c['last_name'] ?? ''}').replaceAll(RegExp(r'\s+'), ' ').trim();
                                          final program = (c['program'] ?? '').toString();
                                          final yearSec = (c['year_section'] ?? '').toString();
                                          final selected = id != null && _selectedIds.contains(id);
                                          final photoUrl = _photoUrlFor(c);
                                          final hasPhoto = c['has_photo'] == true;
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            minLeadingWidth: 40,
                                            leading: SizedBox(
                                              width: _selectionMode ? 64 : 40,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (_selectionMode)
                                                    Checkbox(
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                      value: selected,
                                                      onChanged: id == null
                                                          ? null
                                                          : (v) => setState(() {
                                                                if (v ?? false) {
                                                                  _selectedIds.add(id);
                                                                } else {
                                                                  _selectedIds.remove(id);
                                                                }
                                                              }),
                                                    ),
                                                  InkWell(
                                                    borderRadius: BorderRadius.circular(24),
                                                    onTap: (photoUrl != null && photoUrl.isNotEmpty)
                                                        ? () => _openImage(photoUrl, title: name.isNotEmpty ? name : (c['student_id'] ?? '').toString())
                                                        : null,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(1.5),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                                                      ),
                                                      child: CircleAvatar(
                                                        radius: 15,
                                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                                        child: ClipOval(
                                                          child: (photoUrl != null && photoUrl.isNotEmpty)
                                                              ? Image.network(
                                                                  photoUrl,
                                                                  width: 30,
                                                                  height: 30,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (ctx, e, s) => Text(_initialsFor(c), style: const TextStyle(fontWeight: FontWeight.w700)),
                                                                )
                                                              : (hasPhoto
                                                                  ? const Icon(Icons.person, color: Colors.white)
                                                                  : Text(_initialsFor(c), style: const TextStyle(fontWeight: FontWeight.w700))),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            title: Text(name.isNotEmpty ? name : (c['student_id'] ?? '').toString()),
                                            subtitle: Wrap(
                                              spacing: 12,
                                              runSpacing: 4,
                                              children: [
                                                if (pos.isNotEmpty) Text('Position: $pos'),
                                                if (program.isNotEmpty) Text('Program: $program'),
                                                if (yearSec.isNotEmpty) Text('Section: $yearSec'),
                                              ],
                                            ),
                                            trailing: _selectionMode
                                                ? IconButton(
                                                    tooltip: 'Unregister',
                                                    visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                    icon: const Icon(Icons.person_remove, color: Colors.red, size: 20),
                                                    onPressed: id == null
                                                        ? null
                                                        : () async {
                                                          final ok = await showDialog<bool>(
                                                            context: context,
                                                            barrierDismissible: true,
                                                            builder: (ctx) => AlertDialog(
                                                              title: const Text('Unregister Candidate'),
                                                              content: Text('Unregister ${name.isEmpty ? (c['student_id'] ?? '').toString() : name}?'),
                                                              actions: [
                                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                                                FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Unregister')),
                                                              ],
                                                            ),
                                                          );
                                                          if (ok == true) {
                                                            await _api.deleteCandidate(candidateId: id);
                                                            await _load();
                                                          }
                                                        },
                                                  )
                                                : Wrap(
                                                    spacing: 0,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Edit',
                                                        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                        icon: const Icon(Icons.edit, size: 20),
                                                        onPressed: () async {
                                                          final updated = await Navigator.of(context).push<bool>(
                                                            MaterialPageRoute(
                                                              builder: (_) => CandidateEditScreen(candidate: c),
                                                            ),
                                                          );
                                                          if (updated == true) {
                                                            await _load();
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  final String? title;
  const _FullScreenImageViewer({required this.url, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? 'Image'),
        actions: [
          IconButton(
            tooltip: 'Copy Link',
            icon: const Icon(Icons.link),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied')),
              );
            },
          ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final res = await http.get(Uri.parse(url));
                if (res.statusCode == 200) {
                  final dir = Directory.systemTemp;
                  final ts = DateTime.now().millisecondsSinceEpoch;
                  final file = File('${dir.path}/img_$ts');
                  await file.writeAsBytes(res.bodyBytes);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to ${file.path}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download failed')),
                  );
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download error')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 72, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
