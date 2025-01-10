import 'package:apexo/app/navbar_widget.dart';
import 'package:apexo/app/panel_widget.dart';
import 'package:apexo/app/routes.dart';
import 'package:apexo/common_widgets/back_button.dart';
import 'package:apexo/common_widgets/dialogs/first_launch_dialog.dart';
import 'package:apexo/common_widgets/dialogs/new_version_dialog.dart';
import 'package:apexo/core/multi_stream_builder.dart';
import 'package:apexo/features/network_actions/network_actions_widget.dart';
import 'package:apexo/services/launch.dart';
import 'package:apexo/services/localization/en.dart';
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
            theme: FluentThemeData.light(), // TODO: this is how to implement dark mode
            home: MStreamBuilder(
              streams: [
                version.latest.stream,
                version.current.stream,
                launch.dialogShown.stream,
                launch.isFirstLaunch.stream,
                launch.open.stream,
                routes.showBottomNav.stream,
                routes.panels.stream,
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
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    buildAppLayout(),
                    if (routes.showBottomNav() && routes.panels().isEmpty && launch.open()) const BottomNavBar()
                  ],
                );
              },
            ),
          );
        });
  }

  Widget buildAppLayout() {
    return MStreamBuilder(
      streams: [launch.open.stream, routes.currentRouteIndex.stream, routes.panels.stream],
      key: WK.builder,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => routes.goBack(), // TODO: test this on your phone
        child: LayoutBuilder(builder: (context, constraints) {
          final hideSidePanel = routes.panels().isEmpty || !launch.open();
          return Container(
            color: Colors.white.withValues(alpha: 0.97),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: 0,
                  left: locale.s.$direction == Direction.rtl ? null : 0,
                  right: locale.s.$direction == Direction.rtl ? 0 : null,
                  height: constraints.maxHeight,
                  width: (!hideSidePanel) && constraints.maxWidth > 710
                      ? constraints.maxWidth - 355
                      : constraints.maxWidth,
                  child: Container(
                    decoration: BoxDecoration(boxShadow: kElevationToShadow[6]),
                    child: NavigationView(
                      appBar: NavigationAppBar(
                        automaticallyImplyLeading: false,
                        title: launch.open() ? Txt(routes.currentRoute.title) : Txt(txt("login")),
                        leading: routes.history.isEmpty ? null : const BackButton(key: WK.backButton),
                        // ignore: prefer_const_constructors
                        actions: NetworkActions(key: WK.globalActions),
                      ),
                      onDisplayModeChanged: (mode) {
                        if (mode == PaneDisplayMode.minimal) {
                          routes.showBottomNav(true);
                        } else {
                          routes.showBottomNav(false);
                        }
                      },
                      content: launch.open() ? null : const Login(key: WK.loginScreen),
                      pane: !launch.open()
                          ? null
                          : NavigationPane(
                              autoSuggestBox: const CurrentUser(key: WK.currentUserSection),
                              autoSuggestBoxReplacement: const Icon(FluentIcons.contact),
                              header: const AppLogo(),
                              selected: routes.currentRouteIndex(),
                              displayMode: PaneDisplayMode.auto,
                              toggleable: false,
                              items:
                                  List<NavigationPaneItem>.from(routes.allRoutes.where((p) => p.onFooter != true).map(
                                        (route) => PaneItem(
                                          key: Key("${route.identifier}_screen_button"),
                                          icon: route.accessible ? Icon(route.icon) : const Icon(FluentIcons.lock),
                                          body: route.accessible
                                              ? Padding(
                                                  padding: EdgeInsets.only(bottom: routes.showBottomNav() ? 55 : 0),
                                                  child: (route.screen)(),
                                                )
                                              : const SizedBox(),
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
                ),
                AnimatedPositioned(
                  width: 350,
                  height: constraints.maxHeight,
                  top: 0,
                  left: locale.s.$direction == Direction.ltr ? null : (hideSidePanel ? -400 : 0),
                  right: locale.s.$direction == Direction.ltr ? (hideSidePanel ? -400 : 0) : null,
                  duration: const Duration(milliseconds: 350),
                  child: hideSidePanel
                      ? const SizedBox()
                      : PanelScreen(
                          key: Key(routes.panels().last.identifier),
                          height: constraints.maxHeight,
                          panel: routes.panels().last,
                        ),
                ),
                AnimatedPositioned(
                    top: 2,
                    right: locale.s.$direction == Direction.ltr ? (hideSidePanel ? -400 : 325) : null,
                    left: locale.s.$direction == Direction.ltr ? null : (hideSidePanel ? -400 : 325),
                    duration: const Duration(milliseconds: 350),
                    child: Acrylic(
                      elevation: 20,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
                      child: Container(
                        height: 25,
                        width: 25,
                        alignment: AlignmentDirectional.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Text(
                          routes.panels().length.toString(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ))
              ],
            ),
          );
        }),
      ),
    );
  }
}
