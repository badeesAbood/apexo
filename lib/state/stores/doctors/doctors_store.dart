import 'doctor_model.dart';
import '../../state.dart';
import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../backend/observable/store.dart';

const _storeName = "doctors";

class Doctors extends Store<Doctor> {
  Doctors()
      : super(
          modeling: Doctor.fromJson,
          onSyncStart: () {
            state.isSyncing++;
            state.notify();
          },
          onSyncEnd: () {
            state.isSyncing--;
            state.notify();
          },
        );

  @override
  init() {
    super.init();
    state.activators[_storeName] = () async {
      await loaded;
      local = SaveLocal(_storeName);
      await deleteMemoryAndLoadFromPersistence();

      remote = SaveRemote(
        pbInstance: state.pb!,
        storeName: _storeName,
        onOnlineStatusChange: (current) {
          if (state.isOnline != current) {
            state.isOnline = current;
            state.notify();
          }
        },
      );

      return () async {
        state.setLoadingIndicator("Synchronizing doctors");
        await synchronize();
        globalActions.syncCallbacks[_storeName] = synchronize;
        globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
      };
    };
  }

  Map<String, Doctor> get showing {
    if (state.showArchived) return docs;
    return present;
  }

  Doctor? getByEmail(String email) {
    for (var member in present.values) {
      if (member.email == email) return member;
    }
    return null;
  }
}

final doctors = Doctors();
// don't forget to initialize it in main.dart
