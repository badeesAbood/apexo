import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';

/// Use this widget to display the logo and name of your app
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: WK.appLogo,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          "assets/images/logo.png",
          height: 25,
        ),
      ),
    );
  }
}
