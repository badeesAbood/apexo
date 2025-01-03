import 'package:apexo/core/observable.dart';
import 'package:apexo/utils/logger.dart';
import 'package:apexo/services/login.dart';
import 'package:pocketbase/pocketbase.dart';

class _Users {
  final list = ObservableState(List<RecordModel>.from([]));
  final loaded = ObservableState(false);
  final loading = ObservableState(false);
  final creating = ObservableState(false);
  final errorMessage = ObservableState("");
  final updating = ObservableState(Map<String, bool>.from({}));
  final deleting = ObservableState(Map<String, bool>.from({}));

  Future<void> newUser(String email, String password) async {
    errorMessage("");
    creating(true);
    try {
      await login.pb!.collection("users").create(body: {
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "verified": true,
      });
    } catch (e) {
      errorMessage((e as ClientException).response.toString());
    }

    await reloadFromRemote();
    creating(false);
  }

  Future<void> delete(RecordModel user) async {
    errorMessage("");
    deleting(deleting()..addAll({user.id: true}));
    await login.pb!.collection("users").delete(user.id);
    deleting(deleting()..remove(user.id));
    await reloadFromRemote();
  }

  Future<void> update(String id, String email, String password) async {
    errorMessage("");
    updating(updating()..addAll({id: true}));
    try {
      await login.pb!.collection("users").update(id, body: {
        "email": email,
        "verified": true,
        if (password.isNotEmpty) "password": password,
        if (password.isNotEmpty) "passwordConfirm": password,
      });
    } catch (e) {
      errorMessage((e as ClientException).response.toString());
    }
    updating(updating()..remove(id));
    await reloadFromRemote();
  }

  Future<void> reloadFromRemote() async {
    if (login.isAdmin == false || login.pb == null || login.token.isEmpty || login.pb!.authStore.isValid == false) {
      return;
    }
    loading(true);
    try {
      list(await login.pb!.collection("users").getFullList());
    } catch (e, s) {
      logger("Error when getting full list of users service: $e", s);
    }
    loaded(true);
    loading(false);
  }
}

final users = _Users();
