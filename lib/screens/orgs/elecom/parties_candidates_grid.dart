import 'package:flutter/material.dart';

class PartiesCandidatesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> parties;
  final bool loading;
  final void Function(Map<String, dynamic> party)? onPartyTap;
  const PartiesCandidatesGrid({
    super.key,
    required this.parties,
    required this.loading,
    this.onPartyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (parties.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No parties registered yet', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final items = parties;
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: items.map((p) {
        final logoUrl = p['logoUrl'] as String?;
        final name = (p['name'] ?? '').toString();
        final isDarkMode = theme.brightness == Brightness.dark;
        return InkWell(
          onTap: onPartyTap == null ? null : () => onPartyTap!(p),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? theme.cardColor : const Color(0xFFF1EEF8),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: logoUrl != null
                        ? Image.network(
                            logoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.flag,
                              color: Color(0xFF6E63F6),
                            ),
                          )
                        : const Icon(Icons.flag, color: Color(0xFF6E63F6)),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
