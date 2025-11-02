import 'package:flutter/material.dart';
import 'dart:ui';
import '../login_screen.dart';
import '../../services/api_service.dart';
import 'candidate_registration_screen.dart';
import 'delete_candidates_screen.dart';
import 'candidates_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:societree_app/config/api_config.dart';

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
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Logout'),
                        ),
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
                      final picker = ImagePicker();
                      XFile? partyLogo;
                      return StatefulBuilder(
                        builder: (ctx, setState) {
                          return BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: AlertDialog(
                              title: const Text('Candidate Type'),
                              content: SingleChildScrollView(
                                child: Column(
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
                                        decoration: const InputDecoration(
                                          labelText: 'Party name',
                                        ),
                                      ),
                                    if (candidateType == 'Political Party') ...[
                                      const SizedBox(height: 8),
                                      if (partyLogo != null) ...[
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 8,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(partyLogo!.path),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () async {
                                                final picked = await picker.pickImage(
                                                  source: ImageSource.gallery,
                                                  imageQuality: 85,
                                                );
                                                if (picked != null) {
                                                  setState(() => partyLogo = picked);
                                                }
                                              },
                                              icon: const Icon(Icons.image_outlined),
                                              label: const Text(
                                                'Change Party Logo',
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final picked = await picker.pickImage(
                                                source: ImageSource.gallery,
                                                imageQuality: 85,
                                              );
                                              if (picked != null) {
                                                setState(() => partyLogo = picked);
                                              }
                                            },
                                            icon: const Icon(Icons.image_outlined),
                                            label: const Text('Upload Party Logo (optional)'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
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
                                    final selType = candidateType;
                                    final selName = partyCtrl.text.trim();
                                    final selLogoPath = partyLogo?.path;
                                    Navigator.of(ctx).pop();
                                    final api = ApiService(baseUrl: apiBaseUrl);
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (_) => CandidateRegistrationScreen(
                                              api: api,
                                              initialCandidateType: selType,
                                              initialPartyName: selType == 'Political Party' ? selName : null,
                                              initialPartyLogoPath: selType == 'Political Party' ? selLogoPath : null,
                                            ),
                                          ),
                                        )
                                        .then((_) {
                                          showDialog<void>(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (ctx2) {
                                              String? candidateType = selType;
                                              final partyCtrl = TextEditingController(text: selName);
                                              final picker = ImagePicker();
                                              XFile? partyLogo = selLogoPath != null ? XFile(selLogoPath) : null;
                                              return StatefulBuilder(
                                                builder: (ctx2, setState2) {
                                                  return BackdropFilter(
                                                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                                    child: AlertDialog(
                                                      title: const Text('Candidate Type'),
                                                      content: SingleChildScrollView(
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            RadioListTile<String>(
                                                              title: const Text('Independent'),
                                                              value: 'Independent',
                                                              groupValue: candidateType,
                                                              onChanged: (v) => setState2(() => candidateType = v),
                                                            ),
                                                            RadioListTile<String>(
                                                              title: const Text('Political Party'),
                                                              value: 'Political Party',
                                                              groupValue: candidateType,
                                                              onChanged: (v) => setState2(() => candidateType = v),
                                                            ),
                                                            if (candidateType == 'Political Party')
                                                              TextField(
                                                                controller: partyCtrl,
                                                                decoration: const InputDecoration(labelText: 'Party name'),
                                                              ),
                                                            if (candidateType == 'Political Party') ...[
                                                              const SizedBox(height: 8),
                                                              if (partyLogo != null) ...[
                                                                Wrap(
                                                                  spacing: 12,
                                                                  runSpacing: 8,
                                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                                  children: [
                                                                    ClipRRect(
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      child: Image.file(
                                                                        File(partyLogo!.path),
                                                                        width: 56,
                                                                        height: 56,
                                                                        fit: BoxFit.cover,
                                                                      ),
                                                                    ),
                                                                    TextButton.icon(
                                                                      onPressed: () async {
                                                                        final picked = await picker.pickImage(
                                                                          source: ImageSource.gallery,
                                                                          imageQuality: 85,
                                                                        );
                                                                        if (picked != null) {
                                                                          setState2(() => partyLogo = picked);
                                                                        }
                                                                      },
                                                                      icon: const Icon(Icons.image_outlined),
                                                                      label: const Text(
                                                                        'Change Party Logo',
                                                                        overflow: TextOverflow.ellipsis,
                                                                        maxLines: 1,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ] else ...[
                                                                Align(
                                                                  alignment: Alignment.centerLeft,
                                                                  child: OutlinedButton.icon(
                                                                    onPressed: () async {
                                                                      final picked = await picker.pickImage(
                                                                        source: ImageSource.gallery,
                                                                        imageQuality: 85,
                                                                      );
                                                                      if (picked != null) {
                                                                        setState2(() => partyLogo = picked);
                                                                      }
                                                                    },
                                                                    icon: const Icon(Icons.image_outlined),
                                                                    label: const Text('Upload Party Logo (optional)'),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(ctx2).pop(),
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
                                                            Navigator.of(ctx2).pop();
                                                            final api = ApiService(baseUrl: apiBaseUrl);
                                                            Navigator.of(context).push(
                                                              MaterialPageRoute(
                                                                builder: (_) => CandidateRegistrationScreen(
                                                                  api: api,
                                                                  initialCandidateType: candidateType,
                                                                  initialPartyName: candidateType == 'Political Party' ? partyCtrl.text.trim() : null,
                                                                  initialPartyLogoPath: candidateType == 'Political Party' ? (partyLogo?.path) : null,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: const Text('Continue'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        });
                                  },
                                  child: const Text('Continue'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.people_alt_outlined),
                label: const Text('Candidates'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CandidatesScreen(),
                    ),
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
