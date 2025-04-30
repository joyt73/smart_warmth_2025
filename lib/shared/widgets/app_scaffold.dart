import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool useDarkBackground;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.useDarkBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: title != null ? Text(title!) : null,
        actions: actions,
        leading: showBackButton
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        )
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              useDarkBackground
                  ? 'assets/images/app_dark_background.png'  // Per schermate come Contact
                  : 'assets/images/app_background.png',      // Per schermate di autenticazione
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
    );
  }
}