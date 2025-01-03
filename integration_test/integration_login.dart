import 'package:apexo/services/localization/index.dart';
import 'package:apexo/main.dart';
import 'package:apexo/widget_keys.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/secret.dart';
import 'base.dart';

class LoginPageIntegrationTest extends IntegrationTestBase {
  LoginPageIntegrationTest({required super.tester});

  @override
  String get name => 'login';

  @override
  Map<String, Future<Null> Function()> get tests => {
        '01: Language switch from login page': () async {
          await tester.tap(find.byKey(WK.loginLangComboBox));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('ar')));
          await tester.pumpAndSettle();
          expect(find.text('تسجيل الدخول'), findsExactly(3));
          await tester.tap(find.byKey(WK.loginLangComboBox));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('en')));
          await tester.pumpAndSettle();
          expect(find.text('Login'), findsExactly(3));
        },
        '02: Successful login++': () async {
          await tester.tap(find.widgetWithText(ClipRect, 'Login'));
          await tester.enterText(find.byKey(WK.serverField), testPBServer);
          await tester.enterText(find.byKey(WK.emailField), testPBEmail);
          await tester.enterText(find.byKey(WK.passwordField), testPBPassword);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(WK.btnLogin));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.dashboardScreen), findsOneWidget);
        },
        '03: Logout': () async {
          await tester.tap(find.byKey(WK.btnLogout));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.loginScreen), findsOneWidget);
        },
        '04: Failed login': () async {
          await tester.tap(find.widgetWithText(ClipRect, 'Login'));
          await tester.enterText(find.byKey(WK.serverField), "none");
          await tester.enterText(find.byKey(WK.emailField), "none");
          await tester.enterText(find.byKey(WK.passwordField), "none");
          await tester.tap(find.byKey(WK.btnLogin));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.loginErr), findsOneWidget);
        },
        '05: Reset password': () async {
          await tester.tap(find.widgetWithText(SmallIconButton, 'Reset password'));
          find.widgetWithText(InfoBar, txt("youLLGet"));
          await tester.enterText(find.byKey(WK.emailField), testPBEmail);
          await tester.tap(find.byKey(WK.btnResetPassword));
          await tester.pumpAndSettle();
          find.widgetWithText(InfoBar, txt("beenSent"));
        },
        '06: Successful login 2': () async {
          await tester.tap(find.widgetWithText(ClipRect, 'Login'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(WK.serverField), testPBServer);
          await tester.enterText(find.byKey(WK.emailField), testPBEmail);
          await tester.enterText(find.byKey(WK.passwordField), testPBPassword);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(WK.btnLogin));
          await tester.pumpAndSettle();
          expect(find.byKey(WK.dashboardScreen), findsOneWidget);
        },
        '07: Logged in and showing email': () async {
          expect(find.text(testPBEmail), findsOneWidget);
        },
        '08: Auto login after reload': () async {
          // TODO: this is not really testing the reload
          // and I can't figure out a way to actually restart the application
          await tester.pumpWidget(const ApexoApp());
          await tester.pumpAndSettle();
          expect(find.byKey(WK.dashboardScreen), findsOneWidget);
          expect(find.text('alielselawi@gmail.com'), findsOneWidget);
        },
      };
}
