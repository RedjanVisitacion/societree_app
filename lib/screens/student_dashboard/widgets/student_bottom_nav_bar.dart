import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:societree_app/main.dart';

class StudentBottomNavBar {
  static Widget? build({
    required BuildContext context,
    required bool isElecom,
    required bool isMenuOpen,
    bool isVisible = true,
  }) {
    if (!isElecom) return null;

    final theme = Theme.of(context);

    Widget wrappedNavBar = ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, child) {
        final currentIsDarkMode = themeNotifier.isDarkMode;
        return ClipRect(
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                color: currentIsDarkMode
                    ? const Color(0xFF121212)
                    : theme.scaffoldBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: currentIsDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[300],
                    ),
                    BottomNavigationBar(
                      backgroundColor: currentIsDarkMode
                          ? const Color(0xFF121212)
                          : theme.scaffoldBackgroundColor,
                      selectedItemColor: currentIsDarkMode
                          ? Colors.white
                          : theme.colorScheme.primary,
                      unselectedItemColor: currentIsDarkMode
                          ? Colors.white70
                          : Colors.grey[600],
                      selectedLabelStyle: TextStyle(
                        color: currentIsDarkMode ? Colors.white : null,
                      ),
                      unselectedLabelStyle: TextStyle(
                        color: currentIsDarkMode ? Colors.white70 : null,
                      ),
                      elevation: 0,
                      currentIndex: 0,
                      onTap: (i) {
                        if (i != 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                [
                                  'Home',
                                  'Election',
                                  'Poll History',
                                  'Status',
                                ][i],
                              ),
                            ),
                          );
                        }
                      },
                      type: BottomNavigationBarType.fixed,
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.home_outlined,
                            color: currentIsDarkMode ? Colors.white70 : null,
                          ),
                          activeIcon: Icon(
                            Icons.home_outlined,
                            color: currentIsDarkMode ? Colors.white : null,
                          ),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.how_to_vote_outlined,
                            color: currentIsDarkMode ? Colors.white70 : null,
                          ),
                          activeIcon: Icon(
                            Icons.how_to_vote_outlined,
                            color: currentIsDarkMode ? Colors.white : null,
                          ),
                          label: 'Election',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.history,
                            color: currentIsDarkMode ? Colors.white70 : null,
                          ),
                          activeIcon: Icon(
                            Icons.history,
                            color: currentIsDarkMode ? Colors.white : null,
                          ),
                          label: 'Poll History',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.check,
                            color: currentIsDarkMode ? Colors.white70 : null,
                          ),
                          activeIcon: Icon(
                            Icons.check,
                            color: currentIsDarkMode ? Colors.white : null,
                          ),
                          label: 'Status',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (isMenuOpen) {
      return Stack(
        children: [
          wrappedNavBar,
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
        ],
      );
    }

    return wrappedNavBar;
  }
}
