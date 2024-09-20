import "../backend/observable/observable.dart";

import "en.dart";
import "ar.dart";

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
