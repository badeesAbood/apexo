import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/state/state.dart';
import 'package:pocketbase/pocketbase.dart';

class Admins extends ObservableObject {
  List<AdminModel> list = [];
  bool loaded = false;
  bool loading = false;
  bool creating = false;
  String errorMessage = "";
  Map<String, bool> updating = {};
  Map<String, bool> deleting = {};

  Future<void> newAdmin(String email, String password) async {
    errorMessage = "";
    creating = true;
    notify();
    try {
      await state.pb!.admins.create(body: {
        "email": email,
        "password": password,
        "passwordConfirm": password,
      });
    } catch (e) {
      errorMessage = (e as ClientException).response.toString();
    }

    await reloadFromRemote();
    creating = false;
    notify();
  }

  Future<void> delete(AdminModel admin) async {
    errorMessage = "";
    deleting.addAll({admin.id: true});
    notify();
    await state.pb!.admins.delete(admin.id);
    deleting.remove(admin.id);
    await reloadFromRemote();
  }

  Future<void> update(String id, String email, String password) async {
    errorMessage = "";
    updating.addAll({id: true});
    notify();
    try {
      await state.pb!.admins.update(id, body: {
        "email": email,
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
    list = await state.pb!.admins.getFullList();
    loaded = true;
    loading = false;
    notify();
  }
}

final admins = Admins();
