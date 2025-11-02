import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:societree_app/screens/orgs/elecom/omnibus_slideshow.dart';
import 'package:societree_app/screens/orgs/elecom/parties_candidates_grid.dart';
import 'package:societree_app/screens/orgs/elecom/things_to_know.dart';
import 'package:societree_app/screens/student_dashboard/widgets/election_info_sheets.dart';

class ElecomDashboardContent extends StatelessWidget {
  final ThemeData theme;
  final Duration remaining;
  final bool voted;
  final String? selectedCandidate;
  final List<Map<String, dynamic>> parties;
  final bool loadingParties;
  final bool showAllParties;
  final List<Map<String, dynamic>> candidates;
  final Function(bool) onToggleShowAllParties;
  final Function(bool) onVoteSubmitted;
  final Function(Map<String, dynamic>) onShowPartyDetails;

  const ElecomDashboardContent({
    super.key,
    required this.theme,
    required this.remaining,
    required this.voted,
    this.selectedCandidate,
    required this.parties,
    required this.loadingParties,
    required this.showAllParties,
    required this.candidates,
    required this.onToggleShowAllParties,
    required this.onVoteSubmitted,
    required this.onShowPartyDetails,
  });

  @override
  Widget build(BuildContext context) {
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
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/search',
                  arguments: {
                    'parties': parties,
                    'candidates': candidates,
                    'isElecom': true,
                  },
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search Party/candidates',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: const Color(0xFFF1EEF8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Election Countdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7B6CF6),
                    Color(0xFFB07CF3),
                    Color(0xFFE7B56A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'USTP-OROQUIETA Election',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'General Election to legislative assembly',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
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
                    days > 0
                        ? 'You have $days days left to vote. Don\'t miss your chance!'
                        : 'Voting closes soon!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFFFE4E4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E63F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                      ),
                      onPressed: voted
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                barrierDismissible: true,
                                builder: (ctx) {
                                  return BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: AlertDialog(
                                      title: const Text('Confirm Vote'),
                                      content: Text(
                                        selectedCandidate == null
                                            ? 'Proceed to vote?'
                                            : 'Cast your vote for "$selectedCandidate"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                              if (ok == true && context.mounted) {
                                onVoteSubmitted(true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vote submitted'),
                                  ),
                                );
                              }
                            },
                      child: const Text('Vote Now'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Omnibus Code',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const OmnibusSlideshow(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parties & Candidates',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (parties.length > 3)
                  TextButton.icon(
                    onPressed: () => onToggleShowAllParties(!showAllParties),
                    icon: Icon(
                      showAllParties
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      size: 18,
                    ),
                    label: Text(showAllParties ? 'See Less' : 'See All'),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            PartiesCandidatesGrid(
              parties: showAllParties
                  ? parties
                  : (parties.length > 3 ? parties.take(3).toList() : parties),
              loading: loadingParties,
              onPartyTap: (party) => onShowPartyDetails(party),
            ),
            const SizedBox(height: 24),
            Text(
              'Things to know',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ThingsToKnowGrid(
              onTopManifesto: () => openManifestoHighlights(context),
              onFaqs: () => openFaqsEducation(context),
              onFindPolling: () => openFindPollingStation(context),
            ),
          ],
        ),
        const SizedBox.shrink(),
      ],
    );
  }
}
