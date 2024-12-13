## Unit testing
Since some unit tests can't be run in parallel, use the following command to run all tests in the project:

```bash
flutter test test/unit/backend_test;
flutter test test/unit/observable_test/model_test.dart;
flutter test test/unit/observable_test/observable_test.dart;
flutter test test/unit/observable_test/observing_widget_test.dart;
flutter test test/unit/observable_test/observing_widget_test.dart;
flutter test test/unit/observable_test/save_local_test.dart;
flutter test test/unit/observable_test/save_remote_test.dart;
flutter test test/unit/observable_test/store_test.dart;
echo "All tests passed!";
```