import 'package:flutter/material.dart';
import 'dart:ui';

class StudentBottomNavBar {
  static Widget? build({
    required BuildContext context,
    required bool isElecom,
    required bool isMenuOpen,
  }) {
    if (!isElecom) return null;

    final bottomNavBar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, thickness: 1),
        BottomNavigationBar(
          currentIndex: 0,
          onTap: (i) {
            if (i != 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ['Home', 'Election', 'Poll History', 'Status'][i],
                  ),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.how_to_vote_outlined),
              label: 'Election',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Poll History',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Status'),
          ],
        ),
      ],
    );

    if (isMenuOpen) {
      return Stack(
        children: [
          bottomNavBar,
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

    return bottomNavBar;
  }
}
