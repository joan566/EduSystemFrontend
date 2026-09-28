import 'package:flutter/material.dart';

class ForgotPasswordMobileView extends StatelessWidget {
  const ForgotPasswordMobileView({
    super.key,
    required this.onBack,
    required this.content,
  });

  final VoidCallback onBack;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: onBack)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: content,
      ),
    );
  }
}
