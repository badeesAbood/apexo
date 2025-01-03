## Unit testing
Since some unit tests can't be run in parallel, use the following command to run all tests in the project:

// TODO: update the following command
```bash
flutter test test/unit/utils_test;
flutter test test/unit/services_test/;
flutter test test/unit/core_test/model_test.dart;
flutter test test/unit/core_test/multi_stream_builder_test.dart;
flutter test test/unit/core_test/observable_test.dart;
flutter test test/unit/core_test/save_local_test.dart;
flutter test test/unit/core_test/save_remote_test.dart;
flutter test test/unit/core_test/store_test.dart;
echo "Finished Running tests!";
```