import 'dart:convert';

import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/state/state.dart';

class Permissions extends ObservableObject {
  List<bool> list = [false, false, false, false, false];
  List<bool> editingList = [false, false, false, false, false];

  bool get edited {
    return jsonEncode(editingList) != jsonEncode(list);
  }

  reset() {
    editingList = [...list];
    notify();
  }

  save() async {
    list = editingList;
    await state.pb!.collection("data").update("permissions____", body: {
      "data": {
        "id": "permissions____",
        "value": jsonEncode(editingList),
        "date": DateTime.now().millisecondsSinceEpoch,
      }
    });
    await reloadFromRemote();
    notify();
  }

  Future<void> reloadFromRemote() async {
    if (state.pb == null || state.token.isEmpty || state.pb!.authStore.isValid == false) {
      return;
    }
    notify();
    try {
      list = List<bool>.from(
          jsonDecode((await state.pb!.collection("data").getOne("permissions____")).getDataValue("data")["value"]));
      editingList = [...list];
    } catch (e, s) {
      logger("Error when getting full list of permissions service: $e", s);
    }
    notify();
    pages.allPages = pages.genAllPages();
    pages.notify();
  }
}

final permissions = Permissions();
