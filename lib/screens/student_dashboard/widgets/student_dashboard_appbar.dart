import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:societree_app/screens/societree/societree_dashboard.dart';
import 'package:societree_app/screens/login_screen.dart';

class StudentDashboardAppBar {
  static PreferredSizeWidget build({
    required BuildContext context,
    required String orgName,
    required bool isElecom,
    required Function(bool) onMenuStateChanged,
  }) {
    final theme = Theme.of(context);
    return AppBar(
      automaticallyImplyLeading: !isElecom,
      title: isElecom
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
          : Text(orgName),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.help_outline)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.more_vert),
          offset: const Offset(0, 7),
          position: PopupMenuPosition.under,
          elevation: 4,
          padding: EdgeInsets.zero,
          iconSize: 24,
          color: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
          onOpened: () => onMenuStateChanged(true),
          onCanceled: () => onMenuStateChanged(false),
          onSelected: (value) async {
            onMenuStateChanged(false);
            if (value == 'home') {
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SocieTreeDashboard()),
              );
            } else if (value == 'logout') {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (ctx) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              );
              if (confirm == true && context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'home',
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/Icon-CRCL.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Societree'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.exit_to_app, size: 20),
                  SizedBox(width: 10),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
