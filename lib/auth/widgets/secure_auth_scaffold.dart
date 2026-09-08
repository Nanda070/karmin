import 'package:flutter/material.dart';

import 'package:karmin/app/widgets/karmin_scaffold.dart';
import 'package:karmin/auth/secure_flag.dart';

/// Auth chrome with FLAG_SECURE best-effort while the route is visible.
class SecureAuthScaffold extends StatefulWidget {
  const SecureAuthScaffold({
    super.key,
    required this.body,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final bool resizeToAvoidBottomInset;

  @override
  State<SecureAuthScaffold> createState() => _SecureAuthScaffoldState();
}

class _SecureAuthScaffoldState extends State<SecureAuthScaffold> {
  @override
  void initState() {
    super.initState();
    SecureFlag.setEnabled(true);
  }

  @override
  void dispose() {
    SecureFlag.setEnabled(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KarminScaffold(
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      body: widget.body,
    );
  }
}
