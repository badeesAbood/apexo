import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Use this widget to display the logo and name of your app
class AppLogo extends StatefulWidget {
  const AppLogo({super.key});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  String version = "";

  @override
  void initState() {
    PackageInfo.fromPlatform().then((p) => setState(() => version = p.version)).ignore();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: WK.appLogo,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 25,
            ),
            const SizedBox(width: 5),
            Text(
              version,
              style: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
