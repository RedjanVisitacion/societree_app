import 'package:flutter/material.dart';
import 'package:societree_app/screens/student_dashboard/utils/photo_viewer.dart';
import 'package:societree_app/screens/student_dashboard/utils/position_utils.dart';
import 'package:societree_app/screens/student_dashboard/widgets/candidate_details_sheet.dart';

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

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
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
                      onTap: logoUrl == null
                          ? null
                          : () => openPhoto(context, logoUrl),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFF1EEF8),
                        child: ClipOval(
                          child: logoUrl != null
                              ? Image.network(
                                  logoUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(
                                    Icons.flag,
                                    color: Color(0xFF6E63F6),
                                  ),
                                )
                              : const Icon(
                                  Icons.flag,
                                  color: Color(0xFF6E63F6),
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
                            ),
                          ),
                          Text(
                            '${partyCandidates.length} candidate${partyCandidates.length == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
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
                      for (final pos in sortedPositions) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            pos,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...partyCandidates
                            .where(
                              (c) => (c['position'] ?? '').toString() == pos,
                            )
                            .map((c) {
                              final photo = c['photoUrl'] as String?;
                              final nm = (c['name'] ?? '').toString();
                              final prg = (c['program'] ?? '').toString();
                              final ys = (c['year_section'] ?? '').toString();
                              final subtitle = [
                                prg,
                                ys,
                              ].where((s) => s.isNotEmpty).join(' • ');
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEAEAEA),
                                  foregroundColor: Colors.grey,
                                  backgroundImage: photo != null
                                      ? NetworkImage(photo)
                                      : null,
                                  child: photo == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  nm,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: subtitle.isNotEmpty
                                    ? Text(subtitle)
                                    : null,
                                onTap: () => showCandidateDetails(context, c),
                              );
                            })
                            .toList(),
                        const SizedBox(height: 8),
                      ],
                      if (partyCandidates.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No candidates found',
                              style: theme.textTheme.bodyMedium,
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
      );
    },
  );
}
