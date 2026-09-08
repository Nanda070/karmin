import 'package:flutter/material.dart';

import 'package:karmin/app/widgets/karmin_scaffold.dart';
import 'package:karmin/auth/widgets/karmin_mark.dart';

class BootPage extends StatelessWidget {
  const BootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const KarminScaffold(
      body: Center(child: KarminMark()),
    );
  }
}
