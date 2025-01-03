import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/test_utils.dart';
import 'base.dart';

class LabworksIntegrationTest extends IntegrationTestBase {
  LabworksIntegrationTest({required super.tester});

  @override
  String get name => 'labworks';

  @override
  Map<String, Future<Null> Function()> get tests => {
        "01: Should move to labworks page": () async {
          await tester.tap(find.byKey(const Key('labworks_screen_button')));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.labworksScreen), findsOneWidget);
        },
        "02: should add labwork with the necessary details": () async {
          await tester.tap(find.text("Add"));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(WK.fieldLabworkTitle));
          await tester.enterText(find.byKey(WK.fieldLabworkTitle), "Zirconia crown");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkOrderNotes), "some notes about the order");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Date"));
          await tester.pumpAndSettle();
          await TestUtils.enterDate(tester, 2022, 12, 25);
          await tester.pumpAndSettle();
          await TestUtils.inputTag(tester, WK.fieldOperators, "Ali A. Saleem", "ali");
          await tester.pumpAndSettle();
          await TestUtils.inputTag(tester, WK.fieldPatient, "Alawi", "al");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkPrice), "30");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkLabName), "Everest");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkPhoneNumber), "07518096323");
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();

          await tester.tap(find.text("Add"));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkTitle), "Ceramic crown");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkOrderNotes), "some notes about the second order");
          await tester.pumpAndSettle();
          await tester.tap(find.text("Change Date"));
          await tester.pumpAndSettle();
          await TestUtils.enterDate(tester, 2022, 12, 2);
          await tester.pumpAndSettle();
          await TestUtils.inputTag(tester, WK.fieldOperators, "Alia A. Saleem", "ali");
          await tester.pumpAndSettle();
          await TestUtils.inputTag(tester, WK.fieldPatient, "Dandoon", "dan");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkPrice), "20");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkLabName), "Han");
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkPhoneNumber), "07718096323");
          await tester.tap(find.text("Save"));
          await tester.pumpAndSettle();
        },
        "03: should auto-complete labwork phone number": () async {
          await tester.tap(find.text("Add"));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.fieldLabworkLabName), "ha");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Han");
          await tester.pumpAndSettle();
          expect(find.descendant(of: find.byKey(WK.fieldLabworkPhoneNumber), matching: find.text("07718096323")),
              findsOneWidget);
          await tester.tap(find.byKey(WK.fieldLabworkLabName));
          await tester.enterText(find.byKey(WK.fieldLabworkLabName), "eve");
          await tester.pumpAndSettle();
          await TestUtils.tapFromTagInput(tester, "Everest");
          await tester.pumpAndSettle();
          expect(find.descendant(of: find.byKey(WK.fieldLabworkPhoneNumber), matching: find.text("07518096323")),
              findsOneWidget);
          await tester.tap(find.text("Cancel"));
          await tester.pumpAndSettle();
        },
      };
}
