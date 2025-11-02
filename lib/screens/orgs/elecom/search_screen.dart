import 'package:flutter/material.dart';
import 'package:societree_app/screens/orgs/elecom/search_candidates.dart';
import 'package:societree_app/main.dart';

class SearchScreen extends StatelessWidget {
  final List<Map<String, dynamic>> parties;
  final List<Map<String, dynamic>> candidates;
  final bool isElecom;
  const SearchScreen({
    super.key,
    required this.parties,
    required this.candidates,
    this.isElecom = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        final shouldUseDarkMode = isElecom && themeNotifier.isDarkMode;
        final searchTheme = shouldUseDarkMode
            ? ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              )
            : Theme.of(context);

        return Theme(
          data: searchTheme,
          child: Scaffold(
            backgroundColor: shouldUseDarkMode
                ? const Color(0xFF121212)
                : searchTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: shouldUseDarkMode
                  ? const Color(0xFF1E1E1E)
                  : searchTheme.appBarTheme.backgroundColor,
              title: isElecom
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Only show icon in light mode
                        if (!shouldUseDarkMode) ...[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
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
                        ],
                        // Use white text in dark mode, black in light mode
                        Opacity(
                          opacity: shouldUseDarkMode ? 1.0 : 0.7,
                          child: Image.asset(
                            shouldUseDarkMode
                                ? 'assets/images/img_text/elecom_white1.png'
                                : 'assets/images/img_text/elecom_black.png',
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    )
                  : null,
              actions: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: Builder(
              builder: (context) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isElecom ? 0 : 12,
                        16,
                        16,
                      ),
                      child: const _SearchBody(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
      final parties =
          (args['parties'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final candidates =
          (args['candidates'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      return SearchCandidates(
        parties: parties,
        candidates: candidates,
        autofocus: true,
      );
    }
    // Fallback for normal constructor usage via SearchScreen(parties:..., candidates:...)
    final widgetAncestor = context
        .findAncestorWidgetOfExactType<SearchScreen>();
    final parties = widgetAncestor?.parties ?? const <Map<String, dynamic>>[];
    final candidates =
        widgetAncestor?.candidates ?? const <Map<String, dynamic>>[];
    return SearchCandidates(
      parties: parties,
      candidates: candidates,
      autofocus: true,
    );
  }
}
