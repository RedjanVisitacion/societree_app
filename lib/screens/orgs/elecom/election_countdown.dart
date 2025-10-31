import 'package:flutter/material.dart';

class ElectionCountdownCard extends StatelessWidget {
  final Duration remaining;
  final bool voted;
  final VoidCallback? onVote;
  const ElectionCountdownCard({super.key, required this.remaining, required this.voted, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    Widget timePill(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B6CF6), Color(0xFFB07CF3), Color(0xFFE7B56A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/ELECOM.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.how_to_vote, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('USTP-OROQUIETA Election', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'General Election to legislative assembly',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              timePill(days.toString().padLeft(2, '0'), 'days'),
              const SizedBox(width: 8),
              timePill(hours.toString().padLeft(2, '0'), 'hours'),
              const SizedBox(width: 8),
              timePill(minutes.toString().padLeft(2, '0'), 'mins'),
              const SizedBox(width: 8),
              timePill(seconds.toString().padLeft(2, '0'), 'sec'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            days > 0 ? 'You have $days days left to vote. Don\'t miss your chance!' : 'Voting closes soon!',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFFFE4E4)),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E63F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              onPressed: voted ? null : onVote,
              child: const Text('Vote Now'),
            ),
          ),
        ],
      ),
    );
  }
}
