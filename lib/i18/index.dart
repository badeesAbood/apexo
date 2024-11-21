import "package:apexo/i18/ar.dart";

import "../backend/observable/observable.dart";
import "en.dart";
// import "test.dart";

class Localization extends ObservableObject {
  List<En> list = [En(), Ar()];
  int selectedIndex = 0;
  En get s => list[selectedIndex];

  void setSelected(int index) {
    selectedIndex = index;
    notify();
  }
}

Localization locale = Localization();

String txt(String input) {
  if (input.isNotEmpty) {
    // always lowercase first letter
    input = input[0].toLowerCase() + input.substring(1);
  }

  // uncomment the following to test
  // if (locale.s.$name == "Test") {
  //   if (locale.list[0].dictionary[input] == null) {
  //     return "U_$input";
  //   } else {
  //     return "F";
  //   }
  // }

  final term = locale.s.dictionary[input];
  if (term != null) {
    return term;
  }
  return input;
}
