import 'package:fluent_ui/fluent_ui.dart';
import "package:flutter/cupertino.dart" show CupertinoTextField;
import '../panel_logo.dart';
import '../state/state.dart';

class Login extends StatelessWidget {
  Login({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Center(
          child: SizedBox(
        width: 350,
        child: Acrylic(
          child: Container(
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(5),
                boxShadow: kElevationToShadow[24]),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                AppLogo(),
                SizedBox(height: 20),
                if (state.loginError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: InfoBar(
                        title: const Text("Error"), content: Text(state.loginError), severity: InfoBarSeverity.error),
                  ),
                InfoLabel(
                  label: "Database URL",
                  child: CupertinoTextField(controller: state.urlField, enabled: state.loadingIndicator.isEmpty),
                ),
                const SizedBox(height: 10),
                InfoLabel(
                  label: "Token",
                  child: CupertinoTextField(controller: state.tokenField, enabled: state.loadingIndicator.isEmpty),
                ),
                const SizedBox(height: 20),
                if (state.loadingIndicator.isNotEmpty)
                  Column(
                    children: [
                      const ProgressBar(),
                      const SizedBox(height: 10),
                      Text(state.loadingIndicator),
                    ],
                  )
                else
                  Row(
                    children: [
                      FilledButton(
                        onPressed: state.loginButton,
                        child: const Row(children: [Icon(FluentIcons.forward), SizedBox(width: 10), Text("Login")]),
                      ),
                      const SizedBox(width: 10),
                      if (state.loginError.isNotEmpty)
                        FilledButton(
                          onPressed: () => state.loginButton(false),
                          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
                          child: const Row(children: [
                            Icon(FluentIcons.virtual_network),
                            SizedBox(width: 10),
                            Text("Proceed Offline")
                          ]),
                        ),
                    ],
                  ),
              ]),
            ),
          ),
        ),
      )),
    );
  }
}
