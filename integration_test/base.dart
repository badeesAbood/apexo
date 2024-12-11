import 'dart:io';
import 'package:apexo/backend/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, List<String>> passedTests = {};

enum VerbosityLevel {
  verbose, // run all tests including skipped (--) tests
  onlyRequired, // run only important tests (++)
  regular, // run regular and important tests (++)
}

abstract class IntegrationTestBase {
  String get name;
  Map<String, Future<Null> Function()> get tests;
  final WidgetTester tester;

  IntegrationTestBase({required this.tester});

  run([VerbosityLevel verbosityLevel = VerbosityLevel.regular]) async {
    final verbosityFile = (await File("./integration_test/verbosity").readAsString());
    late VerbosityLevel verbosity;

    // verbosity has been defined for all groups
    if (verbosityFile == "--onlyRequired") {
      verbosity = VerbosityLevel.onlyRequired;
    } else if (verbosityFile == "--verbose") {
      verbosity = VerbosityLevel.verbose;
    } else if (verbosityFile == "--regular") {
      verbosity = VerbosityLevel.regular;
    }
    // a specific group is being run verbosely
    else if (verbosityFile == name) {
      verbosity = VerbosityLevel.verbose;
    } else {
      verbosity = VerbosityLevel.onlyRequired;
    }

    List<String> sortedTests = tests.keys.toList()..sort((a, b) => a.compareTo(b));
    if (verbosity == VerbosityLevel.onlyRequired) {
      sortedTests = sortedTests.where((t) => t.endsWith("++")).toList();
    }
    if (verbosity == VerbosityLevel.regular) {
      sortedTests = sortedTests.where((t) => !t.endsWith("--")).toList();
    }
    logger(
        "⭐ Starting test group: $name, in $verbosity mode, will run ${sortedTests.length} out of ${tests.keys.length}",
        null,
        3);
    for (var testName in sortedTests) {
      logger("🧪 Running test: $testName", null, 2);
      await tests[testName]!();
      logger("\x1B[32m👌 Test $testName passed\x1B[0m", null, 3);
      // register the test as passed
      if (passedTests[name] == null) {
        passedTests[name] = [];
      }
      passedTests[name]!.add(testName);
    }
  }
}
