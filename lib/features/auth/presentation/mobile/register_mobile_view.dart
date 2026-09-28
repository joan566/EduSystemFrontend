import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterMobileView extends StatelessWidget {
  const RegisterMobileView({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: form,
        ),
      ),
    );
  }
}
