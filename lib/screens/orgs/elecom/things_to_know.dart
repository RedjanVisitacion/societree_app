import 'package:flutter/material.dart';

class ThingsToKnowGrid extends StatelessWidget {
  const ThingsToKnowGrid({super.key});

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
      children: const [
        _ThingsCard(title: 'Top Manifesto\nHighlights', colors: [Color(0xFFD2B0F6), Color(0xFF9BB4F7)], icon: Icons.article_outlined),
        _ThingsCard(title: 'FAQs & Voter\nEducation', colors: [Color(0xFFE6B1C0), Color(0xFFD5A7F7)], icon: Icons.help_outline),
        _ThingsCard(title: 'Find near by\npolling station', colors: [Color(0xFFA6B6F8), Color(0xFFB7A6F9)], icon: Icons.location_on_outlined),
      ],
    );
  }
}

class _ThingsCard extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final IconData icon;
  const _ThingsCard({required this.title, required this.colors, required this.icon});

  @override
  Widget build(BuildContext context) {
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
}
