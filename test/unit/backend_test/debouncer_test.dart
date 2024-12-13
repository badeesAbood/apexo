import 'package:flutter_test/flutter_test.dart';
import 'package:apexo/backend/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('should execute the action after the specified delay', () async {
      final debouncer = Debouncer(milliseconds: 100);
      bool actionExecuted = false;

      debouncer.run(() {
        actionExecuted = true;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      expect(actionExecuted, isFalse);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(actionExecuted, isTrue);
    });

    test('should cancel the previous action if called again within the delay', () async {
      final debouncer = Debouncer(milliseconds: 100);
      bool actionExecuted = false;

      debouncer.run(() {
        actionExecuted = true;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.run(() {
        actionExecuted = true;
      });

      await Future.delayed(const Duration(milliseconds: 60));
      expect(actionExecuted, isFalse);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(actionExecuted, isTrue);
    });
  });
}
