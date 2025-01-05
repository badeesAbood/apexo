import 'dart:convert';

import 'package:apexo/app/routes.dart';
import 'package:apexo/core/observable.dart';
import 'package:apexo/services/launch.dart';
import 'package:apexo/utils/logger.dart';
import 'package:apexo/services/login.dart';

class _Permissions extends ObservablePersistingObject {
  List<bool> list = launch.isDemo ? [true, true, true, true, true, true] : [false, false, false, false, false, false];
  List<bool> editingList = [false, false, false, false, false, false];

  bool get edited {
    return jsonEncode(editingList) != jsonEncode(list);
  }

  reset() {
    editingList = [...list];
    notifyAndPersist();
  }

  save() async {
    try {
      await login.pb!.collection("data").update("permissions____", body: {
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
    notifyAndPersist();
  }

  Future<void> reloadFromRemote() async {
    final initialNumberOfPermissions = list.length;
    if (login.pb == null || login.token.isEmpty || login.pb!.authStore.isValid == false) {
      return;
    }
    notifyAndPersist();
    try {
      list = List<bool>.from(jsonDecode(
          (await login.pb!.collection("data").getOne("permissions____")).get<Map<String, dynamic>>("data")["value"]));
      // to make things backward compatible we need to check the length and add missing permissions
      if (list.length < initialNumberOfPermissions) {
        list.addAll(List.generate(initialNumberOfPermissions - list.length, (index) => false));
      }
      editingList = [...list];
    } catch (e, s) {
      logger("Error when getting full list of permissions service: $e", s);
    }
    notifyAndPersist();
    routes.allRoutes = routes.genAllRoutes();
    routes.currentRouteIndex(routes.currentRouteIndex());
  }

  _Permissions() : super("permissions");

  @override
  fromJson(Map<String, dynamic> json) {
    final initialNumberOfPermissions = list.length;
    list = json["list"] == null ? [] : List<bool>.from(json["list"]);
    // to make things backward compatible we need to check the length and add missing permissions
    if (list.length < initialNumberOfPermissions) {
      list.addAll(List.generate(initialNumberOfPermissions - list.length, (index) => false));
    }
    editingList = [...list];
    routes.currentRouteIndex(routes.currentRouteIndex());
    reloadFromRemote();
  }

  @override
  Map<String, dynamic> toJson() {
    return {"list": list};
  }
}

final permissions = _Permissions();
