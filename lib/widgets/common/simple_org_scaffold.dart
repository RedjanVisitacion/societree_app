import 'package:flutter/material.dart';

class SimpleOrgScaffold extends StatelessWidget {
  final String title;
  final String asset;
  const SimpleOrgScaffold({super.key, required this.title, required this.asset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFFF0F0F0),
                child: ClipOval(
                  child: Image.asset(
                    asset,
                    width: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.school, size: 56, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Text('Details for $title will appear here.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
