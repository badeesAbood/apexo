import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';
import "package:flutter/cupertino.dart" show CupertinoTextField;
import '../../panel_logo.dart';
import '../../state/state.dart';

class Login extends ObservingWidget {
  const Login({super.key});

  @override
  getObservableState() {
    return [state];
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      bottomBar: state.loginError.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 18.0),
              child:
                  InfoBar(title: const Text("Error"), content: Text(state.loginError), severity: InfoBarSeverity.error),
            )
          : null,
      header: const AppLogo(),
      content: Center(
          child: SizedBox(
        width: 350,
        height: 300,
        child: TabView(
            currentIndex: state.selectedTab,
            onChanged: (input) {
              if (state.loadingIndicator.isEmpty) state.selectedTab = input;
              state.notify();
            },
            closeButtonVisibility: CloseButtonVisibilityMode.never,
            tabs: [
              Tab(
                text: Text("Login"),
                icon: const Icon(FluentIcons.authenticator_app),
                body: buildTabContainer([
                  serverField(),
                  emailField(),
                  passwordField(),
                ], [
                  FilledButton(
                    onPressed: state.loginButton,
                    child: Row(children: [const Icon(FluentIcons.forward), const SizedBox(width: 10), Text("Login")]),
                  ),
                  if (state.loginError.isNotEmpty)
                    FilledButton(
                      onPressed: () => state.loginButton(false),
                      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
                      child: const Row(
                          children: [Icon(FluentIcons.virtual_network), SizedBox(width: 10), Text("Proceed Offline")]),
                    ),
                ]),
              ),
              Tab(
                text: Text("Reset Password"),
                icon: const Icon(FluentIcons.password_field),
                body: buildTabContainer([
                  const SizedBox(height: 1),
                  InfoBar(
                    title: state.resetInstructionsSent
                        ? Text("Reset link has been sent to your email.")
                        : Text("You'll get reset link by email."),
                    severity: state.resetInstructionsSent ? InfoBarSeverity.success : InfoBarSeverity.info,
                  ),
                  const SizedBox(height: 1),
                  serverField(),
                  emailField(),
                ], [
                  if (state.resetInstructionsSent == false)
                    FilledButton(
                      onPressed: state.resetButton,
                      child: Row(children: [
                        const Icon(FluentIcons.password_field),
                        const SizedBox(width: 10),
                        Text("Reset Password")
                      ]),
                    ),
                ]),
              ),
            ]),
      )),
    );
  }

  Container buildTabContainer(List<Widget> fields, List<Widget> actions) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color.fromARGB(255, 250, 250, 250),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...fields.map((field) => [field, const SizedBox(height: 5)]).expand((e) => e),
          if (state.loadingIndicator.isNotEmpty)
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ProgressBar(),
                  const SizedBox(height: 5),
                  Text(state.loadingIndicator),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions.map((e) => [e, const SizedBox(width: 5)]).expand((e) => e).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget serverField() {
    return InfoLabel(
      label: "Server URL",
      child: CupertinoTextField(
          controller: state.urlField,
          enabled: state.loadingIndicator.isEmpty,
          placeholder: "https://[pocketbase server]"),
    );
  }

  Widget emailField() {
    return InfoLabel(
      label: "Email",
      child: CupertinoTextField(
        controller: state.emailField,
        enabled: state.loadingIndicator.isEmpty,
        placeholder: "email@domain.com",
      ),
    );
  }

  Widget passwordField() {
    return InfoLabel(
      label: "Password",
      child: CupertinoTextField(
        controller: state.passwordField,
        enabled: state.loadingIndicator.isEmpty,
        obscureText: true,
      ),
    );
  }
}
