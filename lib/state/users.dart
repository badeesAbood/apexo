import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/state/state.dart';
import 'package:pocketbase/pocketbase.dart';

class Users extends ObservableObject {
  List<RecordModel> list = [];
  bool loaded = false;
  bool loading = false;
  bool creating = false;
  String errorMessage = "";
  Map<String, bool> updating = {};
  Map<String, bool> deleting = {};

  Future<void> newUser(String email, String password) async {
    errorMessage = "";
    creating = true;
    notify();
    try {
      await state.pb!.collection("users").create(body: {
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "verified": true,
      });
    } catch (e) {
      errorMessage = (e as ClientException).response.toString();
    }

    await reloadFromRemote();
    creating = false;
    notify();
  }

  Future<void> delete(RecordModel user) async {
    errorMessage = "";
    deleting.addAll({user.id: true});
    notify();
    await state.pb!.collection("users").delete(user.id);
    deleting.remove(user.id);
    await reloadFromRemote();
  }

  Future<void> update(String id, String email, String password) async {
    errorMessage = "";
    updating.addAll({id: true});
    notify();
    try {
      await state.pb!.collection("users").update(id, body: {
        "email": email,
        "verified": true,
        if (password.isNotEmpty) "password": password,
        if (password.isNotEmpty) "passwordConfirm": password,
      });
    } catch (e) {
      errorMessage = (e as ClientException).response.toString();
    }
    updating.remove(id);
    notify();
    await reloadFromRemote();
  }

  Future<void> reloadFromRemote() async {
    if (state.isAdmin == false || state.pb == null || state.token.isEmpty || state.pb!.authStore.isValid == false) {
      return;
    }
    loading = true;
    notify();
    try {
      list = await state.pb!.collection("users").getFullList();
    } catch (e, s) {
      logger("Error when getting full list of users service: $e", s);
    }
    loaded = true;
    loading = false;
    notify();
  }
}

final users = Users();
