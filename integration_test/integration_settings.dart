import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/test_utils.dart';
import 'base.dart';

class SettingsIntegrationTest extends IntegrationTestBase {
  SettingsIntegrationTest({required super.tester});

  @override
  String get name => 'settings';

  @override
  Map<String, Future<Null> Function()> get tests => {
        "01: Should move to settings page": () async {
          await tester.tap(find.byKey(const Key('settings_page_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.settingsPage), findsOneWidget);
        },

        // "02: should change currency"
        // "03: should change language"
        // "04: should change date format"
        // "05: should starting day of week"
        // "06: should create a new backup"
        // "07: should delete a backup"
        // "08: should create an admin"
        // "09: should delete an admin"
        // "10: should create a user"
        // "11: should delete a user"
        // "12: should change permissions for a user"
      };
}
