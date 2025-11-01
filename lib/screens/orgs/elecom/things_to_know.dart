import 'package:flutter/material.dart';

class ThingsToKnowGrid extends StatelessWidget {
  final VoidCallback? onTopManifesto;
  final VoidCallback? onFaqs;
  final VoidCallback? onFindPolling;
  const ThingsToKnowGrid({super.key, this.onTopManifesto, this.onFaqs, this.onFindPolling});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_element
    Widget card(String title, List<Color> colors, IconData icon) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: [
        _ThingsCard(title: 'Voting\nGuidelines', colors: const [Color(0xFFD2B0F6), Color(0xFF9BB4F7)], icon: Icons.how_to_vote_outlined, onTap: onTopManifesto),
        _ThingsCard(title: 'Election\nFAQs', colors: const [Color(0xFFE6B1C0), Color(0xFFD5A7F7)], icon: Icons.help_outline, onTap: onFaqs),
        _ThingsCard(title: 'Campus polling\nstations', colors: const [Color(0xFFA6B6F8), Color(0xFFB7A6F9)], icon: Icons.location_on_outlined, onTap: onFindPolling),
      ],
    );
  }
}

class _ThingsCard extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final IconData icon;
  final VoidCallback? onTap;
  const _ThingsCard({required this.title, required this.colors, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
