import 'package:flutter/material.dart';
import 'package:societree_app/widgets/common/simple_org_scaffold.dart';

class UsgDashboard extends StatelessWidget {
  const UsgDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleOrgScaffold(title: 'USG', asset: 'assets/images/USG.png');
  }
}
