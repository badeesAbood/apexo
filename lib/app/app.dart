import 'package:apexo/app/routes.dart';
import 'package:apexo/common_widgets/back_button.dart';
import 'package:apexo/common_widgets/dialogs/first_launch_dialog.dart';
import 'package:apexo/common_widgets/dialogs/new_version_dialog.dart';
import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/features/network_actions/network_actions_widget.dart';
import 'package:apexo/services/launch.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:apexo/features/login/login_screen.dart';
import 'package:apexo/common_widgets/current_user.dart';
import 'package:apexo/common_widgets/logo.dart';
import 'package:apexo/services/version.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ApexoApp extends StatelessWidget {
  const ApexoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: locale.selectedLocale.stream,
        builder: (context, _) {
          return FluentApp(
            key: WK.fluentApp,
            locale: Locale(locale.s.$code),
            themeMode: ThemeMode.dark,
            home: MStreamBuilder(
              streams: [
                version.latest.stream,
                version.current.stream,
                launch.dialogShown.stream,
                launch.isFirstLaunch.stream
              ],
              builder: (BuildContext context, _) {
                if (version.newVersionAvailable) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if ((!launch.dialogShown()) && context.mounted) {
                      launch.dialogShown(true);
                      showDialog(context: context, builder: (BuildContext context) => const NewVersionDialog());
                    }
                  });
                }

                if (launch.isFirstLaunch()) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if ((!launch.dialogShown()) && context.mounted) {
                      launch.dialogShown(true);
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return const FirstLaunchDialog();
                          });
                    }
                  });
                }
                return MStreamBuilder(
                  streams: [launch.open.stream, routes.stream],
                  key: WK.builder,
                  builder: (context, _) => PopScope(
                    canPop: false,
                    onPopInvokedWithResult: (_, __) => routes.goBack(), // TODO: test this on your phone
                    child: NavigationView(
                      appBar: NavigationAppBar(
                        automaticallyImplyLeading: false,
                        title: launch.open() ? Txt(routes.currentRoute.title) : Txt(txt("login")),
                        leading: routes.history.isEmpty ? null : const BackButton(key: WK.backButton),
                        // ignore: prefer_const_constructors
                        actions: NetworkActions(key: WK.globalActions),
                      ),
                      content: launch.open() ? null : const Login(key: WK.loginScreen),
                      pane: !launch.open()
                          ? null
                          : NavigationPane(
                              autoSuggestBox: const CurrentUser(key: WK.currentUserSection),
                              autoSuggestBoxReplacement: const Icon(FluentIcons.contact),
                              header: const AppLogo(),
                              selected: routes.currentRouteIndex,
                              displayMode: PaneDisplayMode.auto,
                              items:
                                  List<NavigationPaneItem>.from(routes.allRoutes.where((p) => p.onFooter != true).map(
                                        (route) => PaneItem(
                                          key: Key("${route.identifier}_screen_button"),
                                          icon: route.accessible ? Icon(route.icon) : const Icon(FluentIcons.lock),
                                          body: route.accessible ? (route.screen)() : const SizedBox(),
                                          title: Txt(route.title),
                                          onTap: () => route.accessible ? routes.navigate(route) : null,
                                          enabled: route.accessible,
                                        ),
                                      )),
                              footerItems: [
                                ...routes.allRoutes.where((p) => p.onFooter == true).map(
                                      (route) => PaneItem(
                                        icon: Icon(route.icon),
                                        body: (route.screen)(),
                                        title: Txt(route.title),
                                        onTap: () => routes.navigate(route),
                                      ),
                                    ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          );
        });
  }
}
