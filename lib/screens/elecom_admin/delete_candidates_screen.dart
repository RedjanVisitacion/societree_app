import 'package:flutter/material.dart';
import 'package:societree_app/config/api_config.dart';
import 'package:societree_app/services/api_service.dart';


class DeleteCandidatesScreen extends StatefulWidget {
  const DeleteCandidatesScreen({super.key});

  @override
  State<DeleteCandidatesScreen> createState() => _DeleteCandidatesScreenState();
}

class _DeleteCandidatesScreenState extends State<DeleteCandidatesScreen> {
  final ApiService _api = ApiService(baseUrl: apiBaseUrl);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _candidates = [];
  List<Map<String, dynamic>> _filteredCandidates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCandidates);
    _loadCandidates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCandidates() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredCandidates = _candidates;
      });
      return;
    }

    setState(() {
      _filteredCandidates = _candidates.where((candidate) {
        final studentId = (candidate['student_id'] ?? '')
            .toString()
            .toLowerCase();
        final firstName = (candidate['first_name'] ?? '')
            .toString()
            .toLowerCase();
        final middleName = (candidate['middle_name'] ?? '')
            .toString()
            .toLowerCase();
        final lastName = (candidate['last_name'] ?? '')
            .toString()
            .toLowerCase();
        final name = '$firstName $middleName $lastName'.toLowerCase();
        final organization = (candidate['organization'] ?? '')
            .toString()
            .toLowerCase();
        final position = (candidate['position'] ?? '').toString().toLowerCase();
        final program = (candidate['program'] ?? '').toString().toLowerCase();
        final yearSection = (candidate['year_section'] ?? '')
            .toString()
            .toLowerCase();
        final candidateType = (candidate['candidate_type'] ?? '')
            .toString()
            .toLowerCase();
        final partyName = (candidate['party_name'] ?? '')
            .toString()
            .toLowerCase();

        return studentId.contains(query) ||
            name.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query) ||
            organization.contains(query) ||
            position.contains(query) ||
            program.contains(query) ||
            yearSection.contains(query) ||
            candidateType.contains(query) ||
            partyName.contains(query);
      }).toList();
    });
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getCandidates();
      if (res['success'] == true && res['candidates'] != null) {
        setState(() {
          _candidates = List<Map<String, dynamic>>.from(res['candidates']);
          _filterCandidates();
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

  Future<void> _deleteCandidate(int candidateId, String candidateName) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Candidate'),
          content: Text(
            'Are you sure you want to delete candidate "$candidateName"?',
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
      final res = await _api.deleteCandidate(candidateId: candidateId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ??
                  (res['success'] == true
                      ? 'Candidate deleted'
                      : 'Failed to delete'),
            ),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (res['success'] == true) {
          _loadCandidates();
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
        title: const Text('Delete Candidates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadCandidates,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_loading && _error == null && _candidates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search candidates',
                  hintText: 'Search by name, ID, organization, position...',
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
                          onPressed: _loadCandidates,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredCandidates.isEmpty
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
                              ? 'No candidates found matching your search'
                              : 'No candidates found',
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCandidates,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredCandidates.length,
                      itemBuilder: (context, index) {
                        final candidate = _filteredCandidates[index];
                        final id = candidate['id'] as int?;
                        final studentId = (candidate['student_id'] ?? '')
                            .toString();
                        final firstName = (candidate['first_name'] ?? '')
                            .toString();
                        final middleName = (candidate['middle_name'] ?? '')
                            .toString();
                        final lastName = (candidate['last_name'] ?? '')
                            .toString();
                        final name =
                            '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'
                                .trim();
                        final organization = (candidate['organization'] ?? '')
                            .toString();
                        final position = (candidate['position'] ?? '')
                            .toString();
                        final program = (candidate['program'] ?? '').toString();
                        final yearSection = (candidate['year_section'] ?? '')
                            .toString();
                        final candidateType =
                            (candidate['candidate_type'] ?? '').toString();
                        final partyName = (candidate['party_name'] ?? '')
                            .toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(name.isNotEmpty ? name : studentId),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (studentId.isNotEmpty)
                                  Text('ID: $studentId'),
                                if (organization.isNotEmpty)
                                  Text('Organization: $organization'),
                                if (position.isNotEmpty)
                                  Text('Position: $position'),
                                if (program.isNotEmpty)
                                  Text('Program: $program'),
                                if (yearSection.isNotEmpty)
                                  Text('Section: $yearSection'),
                                if (candidateType.isNotEmpty)
                                  Text('Type: $candidateType'),
                                if (partyName.isNotEmpty)
                                  Text('Party: $partyName'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: id != null
                                  ? () => _deleteCandidate(
                                      id,
                                      name.isNotEmpty ? name : studentId,
                                    )
                                  : null,
                              tooltip: 'Delete candidate',
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
