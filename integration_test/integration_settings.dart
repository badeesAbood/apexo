import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'base.dart';

class SettingsIntegrationTest extends IntegrationTestBase {
  SettingsIntegrationTest({required super.tester});

  @override
  String get name => 'settings';

  @override
  Map<String, Future<Null> Function()> get tests => {
        "01: Should move to settings page": () async {
          await tester.tap(find.byKey(const Key('settings_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.settingsScreen), findsOneWidget);
        },
        "02: Should be able to change currency": () async {
          await tester.tap(find.widgetWithText(GestureDetector, 'Currency'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key("currency_text_field")), "CCH");
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.text("Save"));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.byKey(const Key('calendar_screen_button')));
          await tester.pump(const Duration(seconds: 1));
          expect(find.byKey(WK.calendarScreen), findsOneWidget);
          await tester.tap(find.widgetWithText(GestureDetector, 'Add'));
          await tester.pump(const Duration(seconds: 1));
          expect(find.text("New Patient"), findsOneWidget);
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.byKey(const Key('Operative Details_icon')));
          await tester.pump(const Duration(seconds: 1));
          expect(find.text("Price in CCH"), findsOneWidget);
          await tester.tap(find.text("Cancel"));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.byKey(const Key('settings_screen_button')));
          await tester.pump(const Duration(seconds: 1));
        },
        "03: should change language": () async {
          await tester.tap(find.widgetWithText(GestureDetector, 'Language'));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.byKey(const Key("language_combo")));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.text("العربية"));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.text("Save"));
          await tester.pump(const Duration(seconds: 4));
          expect(find.text("اللغة"), findsOneWidget);
          await tester.tap(find.byKey(const Key("language_combo")));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.text("English"));
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.text("حفظ"));
          await tester.pump(const Duration(seconds: 1));
          expect(find.text("Language"), findsOneWidget);
        },
      };
}
