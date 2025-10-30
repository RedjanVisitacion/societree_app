import 'package:flutter/material.dart';
import 'dart:ui';
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
  final List<String> _elecomCandidates = const [
    'Candidate A',
    'Candidate B',
    'Candidate C',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isElecom = widget.orgName.toUpperCase().contains('ELECOM');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orgName),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xFFF0F0F0),
                    child: ClipOval(
                      child: Image.asset(
                        widget.assetPath,
                        width: 90,
                        height: 90,
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
                  if (isElecom) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color.fromARGB(115, 89, 98, 105), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ELECOM Voting', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            if (_voted)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Text('Thank you! Your vote has been recorded.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade800)),
                              )
                            else ...[
                              ..._elecomCandidates.map((c) => RadioListTile<String>(
                                    title: Text(c),
                                    value: c,
                                    groupValue: _selectedCandidate,
                                    onChanged: (v) => setState(() => _selectedCandidate = v),
                                  )),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.how_to_vote),
                                  label: const Text('Submit Vote'),
                                  onPressed: _selectedCandidate == null
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
                                                  content: Text('Cast your vote for "${_selectedCandidate!}"?'),
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
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
