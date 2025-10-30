import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'candidate_registration_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Admin Dashboard'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Register Candidate'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (ctx) {
                      String? candidateType;
                      final partyCtrl = TextEditingController();
                      return StatefulBuilder(
                        builder: (ctx, setState) {
                          return AlertDialog(
                            title: const Text('Candidate Type'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RadioListTile<String>(
                                  title: const Text('Independent'),
                                  value: 'Independent',
                                  groupValue: candidateType,
                                  onChanged: (v) => setState(() => candidateType = v),
                                ),
                                RadioListTile<String>(
                                  title: const Text('Political Party'),
                                  value: 'Political Party',
                                  groupValue: candidateType,
                                  onChanged: (v) => setState(() => candidateType = v),
                                ),
                                if (candidateType == 'Political Party')
                                  TextField(
                                    controller: partyCtrl,
                                    decoration: const InputDecoration(labelText: 'Party name'),
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  if (candidateType == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select a candidate type')),
                                    );
                                    return;
                                  }
                                  if (candidateType == 'Political Party' && partyCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a party name')),
                                    );
                                    return;
                                  }
                                  Navigator.of(ctx).pop();
                                  final api = ApiService(
                                    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.137.1/societree_api'),
                                  );
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CandidateRegistrationScreen(
                                        api: api,
                                        initialCandidateType: candidateType,
                                        initialPartyName: candidateType == 'Political Party' ? partyCtrl.text.trim() : null,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Continue'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
