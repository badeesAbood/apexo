import 'package:apexo/backend/utils/init_stores.dart';
import 'package:apexo/pages/settings/window_backups.dart';
import 'package:apexo/pages/shared/qrlink.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logging/logging.dart';
import 'pages/shared/transitions/rotate.dart';
import 'pages/login/page_login.dart';
import './panel_aux.dart';
import './panel_logo.dart';
import 'i18/index.dart';
import 'i18/en.dart';
import 'global_actions.dart';
import 'backend/observable/observing_widget.dart';
import 'pages/index.dart';
import 'state/state.dart';

void main() {
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('>>> ${record.level.name}: ${record.time}: ${record.message}');
  });

  initializeStores();

  if (Uri.base.host == "demo.apexo.app") state.isDemo = true;

  runApp(const ApexoApp());
}

class ApexoApp extends ObservingWidget {
  const ApexoApp({super.key});

  @override
  getObservableState() {
    return [state, pages, locale];
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
        key: WK.fluentApp,
        locale: Locale(locale.s.$code),
        themeMode: ThemeMode.dark,
        home: Builder(builder: (BuildContext context) {
          if (state.newVersionAvailable) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!state.dialogShown) {
                state.dialogShown = true;
                if (context.mounted) {
                  showDialog(context: context, builder: (BuildContext context) => const NewVersionDialog());
                }
              }
            });
          }
          return Builder(
            key: WK.builder,
            builder: (context) => PopScope(
              canPop: false,
              onPopInvoked: (_) => pages.goBack(),
              child: NavigationView(
                appBar: NavigationAppBar(
                  automaticallyImplyLeading: false,
                  title: state.loginActive ? Text(pages.currentPage.title) : Text(txt("login")),
                  leading: pages.history.isEmpty ? null : const BackButton(key: WK.backButton),
                  // ignore: prefer_const_constructors
                  actions: GlobalActions(key: WK.globalActions),
                ),
                content: state.loginActive ? null : const Login(key: WK.loginPage),
                pane: state.loginActive != true
                    ? null
                    : NavigationPane(
                        autoSuggestBox: const AuxiliarySection(key: WK.auxSection),
                        autoSuggestBoxReplacement: const Icon(auxiliaryIcon),
                        header: const AppLogo(),
                        selected: pages.currentPageIndex,
                        displayMode: PaneDisplayMode.auto,
                        items: List<NavigationPaneItem>.from(pages.allPages.where((p) => p.onFooter != true).map(
                              (page) => PaneItem(
                                key: Key("${page.identifier}_page_button"),
                                icon: page.accessible ? Icon(page.icon) : const Icon(FluentIcons.lock),
                                body: page.accessible ? (page.body)() : const SizedBox(),
                                title: Text(page.title),
                                onTap: () => page.accessible ? pages.navigate(page) : null,
                                enabled: page.accessible,
                              ),
                            )),
                        footerItems: [
                          ...pages.allPages.where((p) => p.onFooter == true).map(
                                (page) => PaneItem(
                                  icon: Icon(page.icon),
                                  body: (page.body)(),
                                  title: Text(page.title),
                                  onTap: () => pages.navigate(page),
                                ),
                              ),
                        ],
                      ),
              ),
            ),
          );
        }));
  }
}

class GlobalActions extends ObservingWidget {
  @override
  getObservableState() {
    return [globalActions];
  }

  const GlobalActions({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            children: [
              ...globalActions.actions.where((action) => action.hidden != true).map(
                    (action) => Container(
                      margin: const EdgeInsets.only(left: 3),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildActionIcon(action),
                          if (action.badge != null) _buildBadge(action),
                        ],
                      ),
                    ),
                  )
            ],
          )
        ],
      ),
    );
  }

  Container _buildActionIcon(GlobalAction action) {
    return Container(
      margin: action.badge != null ? const EdgeInsets.only(right: 6) : null,
      child: RotatingWrapper(
        key: Key(action.hashCode.toString()),
        rotate: action.animate == true && action.processing == true,
        child: Tooltip(
          message: action.tooltip,
          child: IconButton(
            icon: Icon(
              action.iconData,
              color: action.processing ?? false ? Colors.white : null,
            ),
            onPressed: action.onPressed,
            iconButtonMode: IconButtonMode.large,
            style: ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                iconSize: WidgetStateProperty.all(18),
                backgroundColor:
                    WidgetStatePropertyAll(action.processing ?? false ? action.activeColor : Colors.transparent)),
          ),
        ),
      ),
    );
  }

  Positioned _buildBadge(GlobalAction action) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        height: 14,
        width: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: kElevationToShadow[2],
        ),
        child: Center(child: Text(action.badge ?? "", style: const TextStyle(fontSize: 10))),
      ),
    );
  }
}

class BackButton extends ObservingWidget {
  @override
  getObservableState() {
    return [pages];
  }

  const BackButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: pages.history.isNotEmpty,
      child: Tooltip(
        message: "Back",
        child: IconButton(
            icon: Icon(locale.s.$direction == Direction.rtl ? FluentIcons.forward : FluentIcons.back),
            onPressed: () => pages.goBack()),
      ),
    );
  }
}

class NewVersionDialog extends StatelessWidget {
  const NewVersionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(txt("newVersionDialogTitle")),
          IconButton(icon: const Icon(FluentIcons.cancel), onPressed: () => Navigator.pop(context))
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(txt("newVersionDialogContent")),
          const SizedBox(height: 10),
          const QRLink(link: "https://apexo.app/#getting-started"),
        ],
      ),
      style: dialogStyling(false),
      actions: const [CloseButtonInDialog(buttonText: "close")],
    );
  }
}
