import 'package:fluent_ui/fluent_ui.dart';
import './backend/utils/transitions/rotate.dart';
import './pages/page_login.dart';
import './panel_aux.dart';
import './panel_logo.dart';
import './state/stores/appointments/appointments_store.dart';
import './state/stores/recipes/recipes_store.dart';
import './state/stores/settings/settings_store.dart';
import 'i18/index.dart';
import 'i18/en.dart';
import 'global_actions.dart';
import 'backend/observable/observing_widget.dart';
import 'pages/index.dart';
import 'state/state.dart';

void main() {
  appointments.init();
  recipes.init();
  globalSettings.init();
  localSettings.init();

  runApp(const MyApp());
}

class MyApp extends ObservingWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return FluentApp(
        locale: Locale(locale.selected.$code),
        themeMode: state.themeMode,
        theme: FluentThemeData(accentColor: state.themeAccentColor),
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
              content: state.loginActive ? null : Login(),
              pane: state.loginActive != true
                  ? null
                  : NavigationPane(
                      autoSuggestBox: const AuxiliarySection(),
                      autoSuggestBoxReplacement: const Icon(auxiliaryIcon),
                      header: const AppLogo(),
                      selected: pages.currentPageIndex,
                      displayMode: PaneDisplayMode.auto,
                      items: [
                        ...pages.activePages.where((p) => p.onFooter != true).map(
                              (page) => PaneItem(
                                icon: Icon(page.icon),
                                body: (page.body)(),
                                title: Text(page.title),
                                onTap: () => pages.navigate(page),
                              ),
                            ),
                      ],
                      footerItems: [
                        ...pages.activePages.where((p) => p.onFooter == true).map(
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

class GlobalActions extends StatelessWidget {
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
                          Container(
                            margin: action.badge != null && action.badge != 0 ? const EdgeInsets.only(right: 6) : null,
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
                                      shape: WidgetStatePropertyAll(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                                      iconSize: WidgetStateProperty.all(18),
                                      backgroundColor: WidgetStatePropertyAll(
                                          action.processing ?? false ? action.activeColor : Colors.transparent)),
                                ),
                              ),
                            ),
                          ),
                          if (action.badge != null)
                            Positioned(
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
                                child: Center(child: Text(action.badge ?? "", style: TextStyle(fontSize: 10))),
                              ),
                            ),
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
}

class BackButton extends StatelessWidget {
  const BackButton({super.key});
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: pages.history.isNotEmpty,
      child: Tooltip(
        message: "Back",
        child: IconButton(
            icon: Icon(locale.selected.$direction == Direction.rtl ? FluentIcons.forward : FluentIcons.back),
            onPressed: () => pages.goBack()),
      ),
    );
  }
}
