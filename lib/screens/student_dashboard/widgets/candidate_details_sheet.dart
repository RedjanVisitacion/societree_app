import 'package:flutter/material.dart';
import 'package:societree_app/screens/student_dashboard/utils/photo_viewer.dart';
import 'package:societree_app/main.dart';

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

  final isDarkMode = themeNotifier.isDarkMode;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final sheetTheme = isDarkMode
          ? ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            )
          : Theme.of(ctx);

      return Theme(
        data: sheetTheme,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E1E1E)
                : sheetTheme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, controller) {
              final th = Theme.of(ctx);
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
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : const Color(0xFFEAEAEA),
                            foregroundColor: isDarkMode
                                ? Colors.white70
                                : Colors.grey,
                            backgroundImage: photo != null
                                ? NetworkImage(photo)
                                : null,
                            child: photo == null
                                ? Icon(
                                    Icons.person,
                                    size: 36,
                                    color: isDarkMode ? Colors.white70 : null,
                                  )
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
                                  color: isDarkMode ? Colors.white : null,
                                ),
                              ),
                              Text(
                                pos,
                                style: th.textTheme.bodyMedium?.copyWith(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: isDarkMode ? Colors.grey[700] : null),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.groups_outlined,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            title: Text(
                              'Organization',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                            subtitle: Text(
                              org.isEmpty ? '—' : org,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : null,
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.badge_outlined,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            title: Text(
                              'Position',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                            subtitle: Text(
                              pos.isEmpty ? '—' : pos,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : null,
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.school_outlined,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            title: Text(
                              'Department / Program',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                            subtitle: Text(
                              program.isEmpty ? '—' : program,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : null,
                              ),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.class_outlined,
                              color: isDarkMode ? Colors.white70 : null,
                            ),
                            title: Text(
                              'Year & Section',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                            subtitle: Text(
                              yearSection.isEmpty ? '—' : yearSection,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : null,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              'Platform',
                              style: th.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? Colors.white : null,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              platform.isEmpty ? '—' : platform,
                              style: th.textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? Colors.white70 : null,
                              ),
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
          ),
        ),
      );
    },
  );
}
