import 'package:flutter/material.dart';
import 'package:societree_app/config/api_config.dart';
import 'package:societree_app/services/api_service.dart';


class DeletePartiesScreen extends StatefulWidget {
  const DeletePartiesScreen({super.key});

  @override
  State<DeletePartiesScreen> createState() => _DeletePartiesScreenState();
}

class _DeletePartiesScreenState extends State<DeletePartiesScreen> {
  final ApiService _api = ApiService(baseUrl: apiBaseUrl);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _parties = [];
  List<Map<String, dynamic>> _filteredParties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterParties);
    _loadParties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterParties() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredParties = _parties;
      });
      return;
    }

    setState(() {
      _filteredParties = _parties.where((party) {
        final partyName = (party['party_name'] ?? '').toString().toLowerCase();
        return partyName.contains(query);
      }).toList();
    });
  }

  Future<void> _loadParties() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getParties();
      if (res['success'] == true && res['parties'] != null) {
        setState(() {
          _parties = List<Map<String, dynamic>>.from(res['parties']);
          _filterParties();
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load parties';
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

  Future<void> _deleteParty(String partyName) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Party'),
          content: Text(
            'Are you sure you want to delete party "$partyName"?\n\nThis will delete all candidates associated with this party.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final res = await _api.deleteParty(partyName: partyName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ??
                  (res['success'] == true
                      ? 'Party deleted'
                      : 'Failed to delete'),
            ),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (res['success'] == true) {
          _loadParties();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Parties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadParties,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_loading && _error == null && _parties.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search parties',
                  hintText: 'Search by party name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
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
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadParties,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredParties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No parties found matching your search'
                              : 'No parties found',
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadParties,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredParties.length,
                      itemBuilder: (context, index) {
                        final party = _filteredParties[index];
                        final partyName = (party['party_name'] ?? '')
                            .toString();
                        final hasLogo = party['has_logo'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: hasLogo
                                ? const Icon(Icons.flag, color: Colors.blue)
                                : const Icon(
                                    Icons.flag_outlined,
                                    color: Colors.grey,
                                  ),
                            title: Text(
                              partyName.isNotEmpty
                                  ? partyName
                                  : 'Unknown Party',
                            ),
                            subtitle: Text(hasLogo ? 'Has logo' : 'No logo'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: partyName.isNotEmpty
                                  ? () => _deleteParty(partyName)
                                  : null,
                              tooltip: 'Delete party',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
