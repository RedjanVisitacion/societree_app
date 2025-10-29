import 'package:flutter/material.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String orgName;
  final String assetPath;
  const StudentDashboard({super.key, required this.orgName, required this.assetPath});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orgName),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
