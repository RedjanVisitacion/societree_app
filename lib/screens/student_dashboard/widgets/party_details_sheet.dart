import 'package:flutter/material.dart';
import 'package:societree_app/screens/student_dashboard/utils/photo_viewer.dart';
import 'package:societree_app/screens/student_dashboard/utils/position_utils.dart';
import 'package:societree_app/screens/student_dashboard/widgets/candidate_details_sheet.dart';
import 'package:societree_app/main.dart';

void showPartyDetails(
  BuildContext context,
  Map<String, dynamic> party,
  List<Map<String, dynamic>> allCandidates,
) {
  final name = (party['name'] ?? '').toString();
  final logoUrl = party['logoUrl'] as String?;
  List<Map<String, dynamic>> partyCandidates = allCandidates
      .where((c) {
        final p = (c['party'] ?? c['party_name'] ?? c['organization'] ?? '')
            .toString()
            .trim();
        return p.toLowerCase() == name.toLowerCase();
      })
      .cast<Map<String, dynamic>>()
      .toList();

  final positions = partyCandidates
      .map((e) => (e['position'] ?? '').toString())
      .where((p) => p.isNotEmpty)
      .toSet()
      .toList();

  final sortedPositions = PositionUtils.sortPositions(positions);

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
              final theme = Theme.of(ctx);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: logoUrl == null
                              ? null
                              : () => openPhoto(context, logoUrl),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: isDarkMode
                                ? Colors.grey[800]
                                : const Color(0xFFF1EEF8),
                            child: ClipOval(
                              child: logoUrl != null
                                  ? Image.network(
                                      logoUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Icon(
                                        Icons.flag,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : const Color(0xFF6E63F6),
                                      ),
                                    )
                                  : Icon(
                                      Icons.flag,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : const Color(0xFF6E63F6),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : null,
                                ),
                              ),
                              Text(
                                '${partyCandidates.length} candidate${partyCandidates.length == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall?.copyWith(
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
                          for (final pos in sortedPositions) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                pos,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode ? Colors.white : null,
                                ),
                              ),
                            ),
                            ...partyCandidates
                                .where(
                                  (c) =>
                                      (c['position'] ?? '').toString() == pos,
                                )
                                .map((c) {
                                  final photo = c['photoUrl'] as String?;
                                  final nm = (c['name'] ?? '').toString();
                                  final prg = (c['program'] ?? '').toString();
                                  final ys = (c['year_section'] ?? '')
                                      .toString();
                                  final subtitle = [
                                    prg,
                                    ys,
                                  ].where((s) => s.isNotEmpty).join(' • ');
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
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
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : null,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      nm,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white
                                                : null,
                                          ),
                                    ),
                                    subtitle: subtitle.isNotEmpty
                                        ? Text(
                                            subtitle,
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : null,
                                            ),
                                          )
                                        : null,
                                    onTap: () =>
                                        showCandidateDetails(context, c),
                                  );
                                })
                                .toList(),
                            const SizedBox(height: 8),
                          ],
                          if (partyCandidates.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Text(
                                  'No candidates found',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode ? Colors.white70 : null,
                                  ),
                                ),
                              ),
                            ),
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
