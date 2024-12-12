import 'package:apexo/backend/utils/init_stores.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/main.dart';
import 'package:apexo/state/state.dart';
import 'package:apexo/widget_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'integration_appointments.dart';
import 'integration_calendar.dart';
import 'integration_labworks.dart';
import 'integration_login.dart';
import 'integration_patients.dart';
import 'integration_doctors.dart';
import '../test/test_utils.dart';
import 'base.dart';

void main() async {
  TestUtils.integrationLoggerInit();
  await TestUtils.removeLocalData();
  await TestUtils.resetRemoteData();
  initializeStores();

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration test', () {
    testWidgets('integration test', (tester) async {
      try {
        // Load app widget
        await tester.pumpWidget(const ApexoApp());
        expect(find.byKey(WK.appLogo), findsOneWidget);

        // ------ being integration tests //
        await LoginPageIntegrationTest(tester: tester).run();
        // there's no PB here, so this cuts of the connectivity for faster tests
        state.pb!.baseUrl = "https://apexo.app";
        await doctorsPageIntegrationTest(tester: tester).run();
        await PatientsIntegrationTest(tester: tester).run();
        await AppointmentsIntegrationTest(tester: tester).run();
        await CalendarIntegrationTest(tester: tester).run();
        await LabworksIntegrationTest(tester: tester).run();
        // ------ end integration tests //

        logger('\x1B[32m---------------------------------------------\x1B[0m', null, 3);
        int noOfPassedTests = 0;
        for (var groupName in passedTests.keys) {
          for (var testName in passedTests[groupName]!) {
            logger('\x1B[32m✔️ Passed $groupName: $testName\x1B[0m', null, 3);
            noOfPassedTests++;
          }
        }

        logger('\x1B[32m✔️✔️✔️✔️✔️ ALL ($noOfPassedTests) INTEGRATION TEST SUCCESS!✔️✔️✔️✔️✔️\x1B[0m', null, 3);
        logger('\x1B[32m---------------------------------------------\x1B[0m', null, 3);
      } catch (e, s) {
        logger("Error: $e", s, 1);
        logger('\x1B[31m❌❌❌❌❌ INTEGRATION TEST FAILED! ❌❌❌❌❌\x1B[0m', null, 1);
      }

      await Future.delayed(const Duration(hours: 2));
    });
  });
}
