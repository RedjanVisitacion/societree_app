import 'package:flutter/material.dart';

class SocietreeMainDashboard extends StatelessWidget {
  const SocietreeMainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _OrgItem('ELECOM', 'assets/images/ELECOM.png', '/org/elecom'),
      _OrgItem('USG', 'assets/images/USG.png', '/org/usg'),
      _OrgItem('ARCU', 'assets/images/ARCU.png', '/org/arcu'),
      _OrgItem('SITE', 'assets/images/SITE.png', '/org/site'),
      _OrgItem('PAFE', 'assets/images/PAFE.png', '/org/pafe'),
      _OrgItem('AFPROTECHS', 'assets/images/AFPROTECHS.png', '/org/afprotechs'),
      _OrgItem('ACCESS', 'assets/images/ACCESS.png', '/org/access'),
      _OrgItem('RED CROSS', 'assets/images/REDCROSS.png', '/org/redcross'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Societree')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _OrgCard(item: items[i]),
      ),
    );
  }
}

class _OrgItem {
  final String name;
  final String asset;
  final String route;
  _OrgItem(this.name, this.asset, this.route);
}

class _OrgCard extends StatelessWidget {
  final _OrgItem item;
  const _OrgCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(item.route),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFF0F0F0),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  item.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.groups, size: 40, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(item.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
