import 'package:fluent_ui/fluent_ui.dart';

const greyButtonStyle = ButtonStyle(
  backgroundColor: WidgetStatePropertyAll(Colors.grey),
  foregroundColor: WidgetStatePropertyAll(Colors.white),
);

filledButtonStyle(Color color) => ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(color),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
    );
