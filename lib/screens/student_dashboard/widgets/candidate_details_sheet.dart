import 'package:flutter/material.dart';
import 'package:societree_app/screens/student_dashboard/utils/photo_viewer.dart';

void showCandidateDetails(
  BuildContext context,
  Map<String, dynamic> candidate,
) {
  final name = (candidate['name'] ?? '').toString();
  final org =
      (candidate['organization'] ??
              candidate['party'] ??
              candidate['party_name'] ??
              '')
          .toString();
  final pos = (candidate['position'] ?? '').toString();
  final program = (candidate['program'] ?? '').toString();
  final yearSection = (candidate['year_section'] ?? '').toString();
  final platform = (candidate['platform'] ?? '').toString();
  final photo = candidate['photoUrl'] as String?;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
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
                      onTap: photo == null
                          ? null
                          : () => openPhoto(context, photo),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFEAEAEA),
                        foregroundColor: Colors.grey,
                        backgroundImage: photo != null
                            ? NetworkImage(photo)
                            : null,
                        child: photo == null
                            ? const Icon(Icons.person, size: 36)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: th.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            pos,
                            style: th.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
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
                        child: Text(
                          'Platform',
                          style: th.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          platform.isEmpty ? '—' : platform,
                          style: th.textTheme.bodyMedium,
                        ),
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
