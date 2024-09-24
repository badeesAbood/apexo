import './patient_model.dart';
import '../../state.dart';
import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../backend/observable/store.dart';

const _storeName = "patients";

class Patients extends Store<Patient> {
  Patients()
      : super(
          modeling: Patient.fromJson,
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
    state.activators[_storeName] = (credentials) async {
      await loaded;

      final dbURL = credentials[0];
      final token = credentials[1];

      local = SaveLocal(_storeName);
      await loadFromLocal();

      remote = SaveRemote(
        token: token,
        dbBranchUrl: dbURL,
        tableName: "main",
        store: _storeName,
        onOnlineStatusChange: (current) {
          if (state.isOnline != current) {
            state.isOnline = current;
            state.notify();
          }
        },
      );

      state.setLoadingIndicator("Synchronizing patients");
      await synchronize();

      globalActions.syncCallbacks[_storeName] = synchronize;
      globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
    };
  }

  List<String> get allTags {
    return Set<String>.from(present.expand((doc) => doc.tags)).toList();
  }

  List<Patient> get present {
    return docs.where((doc) => doc.archived != true).toList();
  }

  List<Patient> get showing {
    if (state.showArchived) return docs;
    return present;
  }
}

final patients = Patients();
// don't forget to initialize it in main.dart
