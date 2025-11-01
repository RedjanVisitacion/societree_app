import 'package:flutter/material.dart';
import 'package:societree_app/screens/orgs/elecom/search_candidates.dart';

class SearchScreen extends StatelessWidget {
  final List<Map<String, dynamic>> parties;
  final List<Map<String, dynamic>> candidates;
  final bool isElecom;
  const SearchScreen({super.key, required this.parties, required this.candidates, this.isElecom = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/ELECOM.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/img_text/elecom_black.png',
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, isElecom ? 0 : 12, 16, 16),
            child: const _SearchBody(),
          ),
        ),
      ),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  @override
  Widget build(BuildContext context) {
    // Retrieve arguments from ModalRoute to avoid rebuilding heavy lists via constructor in hot reload
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final parties = (args['parties'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
      final candidates = (args['candidates'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
      return SearchCandidates(parties: parties, candidates: candidates, autofocus: true);
    }
    // Fallback for normal constructor usage via SearchScreen(parties:..., candidates:...)
    final widgetAncestor = context.findAncestorWidgetOfExactType<SearchScreen>();
    final parties = widgetAncestor?.parties ?? const <Map<String, dynamic>>[];
    final candidates = widgetAncestor?.candidates ?? const <Map<String, dynamic>>[];
    return SearchCandidates(parties: parties, candidates: candidates, autofocus: true);
  }
}
