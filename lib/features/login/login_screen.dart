import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/features/login/login_controller.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/settings/settings_stores.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import "package:flutter/cupertino.dart" show CupertinoTextField;
import '../../common_widgets/logo.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: loginCtrl.loginError.stream,
        builder: (context, _) {
          return ScaffoldPage(
            padding: EdgeInsets.zero,
            bottomBar: loginCtrl.loginError().isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: InfoBar(
                        key: WK.loginErr,
                        title: Txt(txt("error")),
                        content: Txt(loginCtrl.loginError()),
                        severity: InfoBarSeverity.error),
                  )
                : null,
            header: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(),
                  StreamBuilder<Object>(
                      stream: locale.selectedLocale.stream,
                      builder: (context, snapshot) {
                        return ComboBox(
                          key: WK.loginLangComboBox,
                          value: localSettings.locale,
                          items: locale.list
                              .map((e) => ComboBoxItem(value: e.$code, key: Key(e.$code), child: Txt(e.$name)))
                              .toList(),
                          onChanged: (code) {
                            final localeIndex = locale.list.indexWhere(
                              (element) => element.$code == code,
                            );
                            if (localeIndex != -1) {
                              locale.selectedLocale(localeIndex);
                            }
                            localSettings.locale = code ?? "en";
                            localSettings.notify();
                          },
                        );
                      }),
                ]),
            content: Center(
                child: SizedBox(
              width: 350,
              height: 350,
              child: MStreamBuilder(
                  streams: [
                    loginCtrl.selectedTab.stream,
                    loginCtrl.loginError.stream,
                    loginCtrl.resetInstructionsSent.stream,
                    locale.selectedLocale.stream,
                    loginCtrl.obscureText.stream,
                  ],
                  builder: (context, _) {
                    return TabView(
                        currentIndex: loginCtrl.selectedTab(),
                        onChanged: (input) {
                          if (loginCtrl.loadingIndicator().isEmpty) loginCtrl.selectedTab(input);
                        },
                        closeButtonVisibility: CloseButtonVisibilityMode.never,
                        tabs: [
                          Tab(
                            key: WK.loginTab,
                            text: Txt(txt("login")),
                            icon: const Icon(FluentIcons.authenticator_app),
                            body: buildTabContainer([
                              serverField(),
                              emailField(),
                              passwordField(),
                            ], [
                              FilledButton(
                                key: WK.btnLogin,
                                onPressed: loginCtrl.loginButton,
                                child: Row(children: [
                                  const Icon(FluentIcons.forward),
                                  const SizedBox(width: 10),
                                  Txt(txt("login"))
                                ]),
                              ),
                              if (loginCtrl.loginError().isNotEmpty)
                                FilledButton(
                                  key: WK.btnProceedOffline,
                                  onPressed: () => loginCtrl.loginButton(false),
                                  style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.grey)),
                                  child: Row(children: [
                                    const Icon(FluentIcons.virtual_network),
                                    const SizedBox(width: 10),
                                    Txt(txt("proceedOffline"))
                                  ]),
                                ),
                            ]),
                          ),
                          Tab(
                            key: WK.forgotPasswordTab,
                            text: Txt(txt("resetPassword")),
                            icon: const Icon(FluentIcons.password_field),
                            body: buildTabContainer([
                              const SizedBox(height: 1),
                              InfoBar(
                                title: loginCtrl.resetInstructionsSent()
                                    ? Txt(key: WK.msgSentReset, txt("beenSent"))
                                    : Txt(key: WK.msgWillSendReset, txt("youLLGet")),
                                severity:
                                    loginCtrl.resetInstructionsSent() ? InfoBarSeverity.success : InfoBarSeverity.info,
                              ),
                              const SizedBox(height: 1),
                              serverField(),
                              emailField(),
                            ], [
                              if (loginCtrl.resetInstructionsSent() == false)
                                FilledButton(
                                  key: WK.btnResetPassword,
                                  onPressed: loginCtrl.resetButton,
                                  child: Row(children: [
                                    const Icon(FluentIcons.password_field),
                                    const SizedBox(width: 10),
                                    Txt(txt("resetPassword"))
                                  ]),
                                ),
                            ]),
                          ),
                        ]);
                  }),
            )),
          );
        });
  }

  Container buildTabContainer(List<Widget> fields, List<Widget> actions) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: const Color.fromARGB(255, 250, 250, 250),
      ),
      child: StreamBuilder(
          stream: loginCtrl.loadingIndicator.stream,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...fields.map((field) => [field, const SizedBox(height: 5)]).expand((e) => e),
                if (loginCtrl.loadingIndicator().isNotEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const ProgressBar(),
                        const SizedBox(height: 5),
                        Txt(loginCtrl.loadingIndicator()),
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
            );
          }),
    );
  }

  Widget serverField() {
    return InfoLabel(
      label: txt("serverUrl"),
      child: CupertinoTextField(
          key: WK.serverField,
          controller: loginCtrl.urlField,
          textDirection: TextDirection.ltr,
          enabled: loginCtrl.loadingIndicator().isEmpty,
          placeholder: "https://[pocketbase server]"),
    );
  }

  Widget emailField() {
    return InfoLabel(
      label: txt("email"),
      child: CupertinoTextField(
        key: WK.emailField,
        controller: loginCtrl.emailField,
        textDirection: TextDirection.ltr,
        enabled: loginCtrl.loadingIndicator().isEmpty,
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
          controller: loginCtrl.passwordField,
          enabled: loginCtrl.loadingIndicator().isEmpty,
          obscureText: loginCtrl.obscureText(),
          suffix: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              onPressed: () => loginCtrl.obscureText(!loginCtrl.obscureText()),
              icon: const Icon(FluentIcons.red_eye, size: 18),
              style: !loginCtrl.obscureText()
                  ? ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.1)),
                    )
                  : null,
            ),
          )),
    );
  }
}
