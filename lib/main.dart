import 'package:apexo/state/stores/labworks/labworks_store.dart';
import 'package:apexo/state/stores/patients/patients_store.dart';
import 'package:apexo/state/stores/staff/staff_store.dart';
import 'package:apexo/version.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logging/logging.dart';
import './backend/utils/transitions/rotate.dart';
import 'pages/login/page_login.dart';
import './panel_aux.dart';
import './panel_logo.dart';
import './state/stores/appointments/appointments_store.dart';
import './state/stores/settings/settings_store.dart';
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

  staff.init();
  patients.init();
  appointments.init();
  globalSettings.init();
  localSettings.init();
  labworks.init();

  runApp(const MyApp());
}

class MyApp extends ObservingWidget {
  const MyApp({super.key});

  @override
  getObservableState() {
    return [state, pages, locale];
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
        locale: Locale(locale.s.$code),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => PopScope(
            canPop: false,
            onPopInvoked: (_) => pages.goBack(),
            child: NavigationView(
              appBar: NavigationAppBar(
                automaticallyImplyLeading: false,
                title: state.loginActive ? Text(pages.currentPage.title) : const Text("Login"),
                leading: pages.history.isEmpty ? null : const BackButton(),
                // ignore: prefer_const_constructors
                actions: GlobalActions(),
              ),
              content: state.loginActive ? null : const Login(),
              pane: state.loginActive != true
                  ? null
                  : NavigationPane(
                      autoSuggestBox: const AuxiliarySection(),
                      autoSuggestBoxReplacement: const Icon(auxiliaryIcon),
                      header: Row(
                        children: [
                          const AppLogo(),
                          Text(
                            "V $version",
                            style: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.3)),
                          )
                        ],
                      ),
                      selected: pages.currentPageIndex,
                      displayMode: PaneDisplayMode.auto,
                      items: List<NavigationPaneItem>.from(pages.allPages.where((p) => p.onFooter != true).map(
                            (page) => PaneItem(
                                icon: page.accessible ? Icon(page.icon) : const Icon(FluentIcons.lock),
                                body: page.accessible ? (page.body)() : const SizedBox(),
                                title: Text(page.title),
                                onTap: () => page.accessible ? pages.navigate(page) : null,
                                enabled: page.accessible),
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
        ));
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
