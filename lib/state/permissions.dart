import 'dart:convert';

import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/pages/index.dart';
import 'package:apexo/state/state.dart';

class Permissions extends ObservablePersistingObject {
  List<bool> list = state.isDemo ? [true, true, true, true, true, true] : [false, false, false, false, false, false];
  List<bool> editingList = [false, false, false, false, false, false];

  bool get edited {
    return jsonEncode(editingList) != jsonEncode(list);
  }

  reset() {
    editingList = [...list];
    notify();
  }

  save() async {
    try {
      await state.pb!.collection("data").update("permissions____", body: {
        "data": {
          "id": "permissions____",
          "value": jsonEncode(editingList),
          "date": DateTime.now().millisecondsSinceEpoch,
        }
      });
    } catch (e, s) {
      logger("Error while saving permissions: $e", s);
    }

    await reloadFromRemote();
    notify();
  }

  Future<void> reloadFromRemote() async {
    final initialNumberOfPermissions = list.length;
    if (state.pb == null || state.token.isEmpty || state.pb!.authStore.isValid == false) {
      return;
    }
    notify();
    try {
      list = List<bool>.from(jsonDecode(
          (await state.pb!.collection("data").getOne("permissions____")).get<Map<String, dynamic>>("data")["value"]));
      // to make things backward compatible we need to check the length and add missing permissions
      if (list.length < initialNumberOfPermissions) {
        list.addAll(List.generate(initialNumberOfPermissions - list.length, (index) => false));
      }
      editingList = [...list];
    } catch (e, s) {
      logger("Error when getting full list of permissions service: $e", s);
    }
    notify();
    pages.allPages = pages.genAllPages();
    pages.notify();
  }

  Permissions() : super("permissions");

  @override
  fromJson(Map<String, dynamic> json) {
    final initialNumberOfPermissions = list.length;
    list = json["list"] == null ? [] : List<bool>.from(json["list"]);
    // to make things backward compatible we need to check the length and add missing permissions
    if (list.length < initialNumberOfPermissions) {
      list.addAll(List.generate(initialNumberOfPermissions - list.length, (index) => false));
    }
    editingList = [...list];
    pages.notify();
    reloadFromRemote();
  }

  @override
  Map<String, dynamic> toJson() {
    return {"list": list};
  }
}

final permissions = Permissions();
