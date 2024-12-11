import 'package:apexo/backend/observable/observing_widget.dart';
import 'package:apexo/i18/index.dart';
import 'package:apexo/state/stores/settings/settings_store.dart';
import 'package:apexo/widget_keys.dart';
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
              child: InfoBar(
                  key: WK.loginErr,
                  title: Text(txt("error")),
                  content: Text(state.loginError),
                  severity: InfoBarSeverity.error),
            )
          : null,
      header:
          Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
        const AppLogo(),
        ComboBox(
          key: WK.loginLangComboBox,
          value: localSettings.locale,
          items: locale.list.map((e) => ComboBoxItem(value: e.$code, key: Key(e.$code), child: Text(e.$name))).toList(),
          onChanged: (code) {
            final l = locale.list.indexWhere(
              (element) => element.$code == code,
            );
            if (l != -1) {
              locale.selectedIndex = l;
            }
            localSettings.locale = code ?? "en";
            localSettings.notify();
            state.notify();
            locale.notify();
          },
        ),
      ]),
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
                key: WK.loginTab,
                text: Text(txt("login")),
                icon: const Icon(FluentIcons.authenticator_app),
                body: buildTabContainer([
                  serverField(),
                  emailField(),
                  passwordField(),
                ], [
                  FilledButton(
                    key: WK.btnLogin,
                    onPressed: state.loginButton,
                    child:
                        Row(children: [const Icon(FluentIcons.forward), const SizedBox(width: 10), Text(txt("login"))]),
                  ),
                  if (state.loginError.isNotEmpty)
                    FilledButton(
                      key: WK.btnProceedOffline,
                      onPressed: () => state.loginButton(false),
                      style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
                      child: Row(children: [
                        const Icon(FluentIcons.virtual_network),
                        const SizedBox(width: 10),
                        Text(txt("proceedOffline"))
                      ]),
                    ),
                ]),
              ),
              Tab(
                key: WK.forgotPasswordTab,
                text: Text(txt("resetPassword")),
                icon: const Icon(FluentIcons.password_field),
                body: buildTabContainer([
                  const SizedBox(height: 1),
                  InfoBar(
                    title: state.resetInstructionsSent
                        ? Text(key: WK.msgSentReset, txt("beenSent"))
                        : Text(key: WK.msgWillSendReset, txt("youLLGet")),
                    severity: state.resetInstructionsSent ? InfoBarSeverity.success : InfoBarSeverity.info,
                  ),
                  const SizedBox(height: 1),
                  serverField(),
                  emailField(),
                ], [
                  if (state.resetInstructionsSent == false)
                    FilledButton(
                      key: WK.btnResetPassword,
                      onPressed: state.resetButton,
                      child: Row(children: [
                        const Icon(FluentIcons.password_field),
                        const SizedBox(width: 10),
                        Text(txt("resetPassword"))
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
      label: txt("serverUrl"),
      child: CupertinoTextField(
          key: WK.serverField,
          controller: state.urlField,
          textDirection: TextDirection.ltr,
          enabled: state.loadingIndicator.isEmpty,
          placeholder: "https://[pocketbase server]"),
    );
  }

  Widget emailField() {
    return InfoLabel(
      label: txt("email"),
      child: CupertinoTextField(
        key: WK.emailField,
        controller: state.emailField,
        textDirection: TextDirection.ltr,
        enabled: state.loadingIndicator.isEmpty,
        placeholder: "email@domain.com",
      ),
    );
  }

  Widget passwordField() {
    return InfoLabel(
      label: txt("password"),
      child: CupertinoTextField(
        key: WK.passwordField,
        textDirection: TextDirection.ltr,
        controller: state.passwordField,
        enabled: state.loadingIndicator.isEmpty,
        obscureText: true,
      ),
    );
  }
}
