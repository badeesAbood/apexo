import 'package:fluent_ui/fluent_ui.dart';

ContentDialogThemeData dialogStyling(bool danger) {
  return ContentDialogThemeData(
    actionsDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: (danger ? Colors.red : Colors.grey).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          )
        ]),
    decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        gradient: LinearGradient(colors: [Colors.white, danger ? Colors.errorSecondaryColor : Colors.white])),
    titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
  );
}
