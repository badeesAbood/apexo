import 'package:fluent_ui/fluent_ui.dart' hide Page;
import '../i18/index.dart';
import '../pages/page_calendar.dart';
import '../pages/page_recipes.dart';
import '../pages/page_settings.dart';
import '../backend/observable/observable.dart';
import "../state/stores/appointments/appointments_store.dart";
import "../state/stores/recipes/recipes_store.dart";
import "../state/stores/settings/settings_store.dart";

class Page {
  IconData icon;
  String title;
  StatelessWidget Function() body;

  /// show in the navigation pane and thus being activated
  bool show;

  /// presence of a dominant page means that no other page can be shown
  bool dominant;

  /// show in the footer of the navigation pane
  bool onFooter;

  /// callback to be called when the page is selected
  void Function()? onSelect;

  Page({
    required this.title,
    required this.icon,
    required this.body,
    this.show = true,
    this.dominant = false,
    this.onFooter = false,
    this.onSelect,
  });
}

class Pages extends ObservableObject {
  final List<Page> allPages = [
    Page(
      title: "My page",
      icon: FluentIcons.calendar,
      body: Calendar.new,
      show: true,
      onSelect: () {
        appointments.synchronize();
      },
    ),
    Page(
      title: locale.selected.recipes,
      icon: FluentIcons.accept,
      body: PageOne.new,
      show: true,
      dominant: false,
      onSelect: () {
        recipes.synchronize();
      },
    ),
    Page(
      title: locale.selected.settings,
      icon: FluentIcons.view,
      body: PageTwo.new,
      show: true,
      dominant: false,
      onFooter: true,
      onSelect: () {
        globalSettings.synchronize();
      },
    ),
  ];

  int currentPageIndex = 0;
  List<int> history = [];

  Page get currentPage {
    return activePages[currentPageIndex];
  }

  List<Page> get activePages {
    var shownPages = allPages.where((page) {
      return page.show;
    });
    var dominantOnly = shownPages.where((page) => page.dominant);
    if (dominantOnly.isNotEmpty) {
      return dominantOnly.toList();
    }
    return shownPages.toList();
  }

  goBack() {
    if (history.isNotEmpty) {
      currentPageIndex = history.removeLast();
      if (currentPage.onSelect != null) {
        currentPage.onSelect!();
      }
    }
    notify();
  }

  navigate(Page page) {
    if (currentPageIndex == activePages.indexOf(page)) return;
    history.add(currentPageIndex);
    currentPageIndex = activePages.indexOf(page);
    if (currentPage.onSelect != null) {
      currentPage.onSelect!();
    }
    notify();
  }
}

final Pages pages = Pages();
