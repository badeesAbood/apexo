import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Use this widget to display the logo and name of your app
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 10,
      children: [
        SvgPicture.asset(
          "assets/images/logo.svg",
          semanticsLabel: "Logo",
          width: 30,
          height: 30,
        ),
        const Text("Apexo Clinic Manager"),
      ],
    );
  }
}
