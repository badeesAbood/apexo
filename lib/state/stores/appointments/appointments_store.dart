import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../state/state.dart';
import './appointment_model.dart';
import '../../../backend/observable/store.dart';

const _storeName = "appointments";

class Appointments extends Store<Appointment> {
  Appointments()
      : super(
          modeling: Appointment.fromJson,
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

      state.setLoadingIndicator("Synchronizing appointments");
      await synchronize();

      globalActions.syncCallbacks[_storeName] = synchronize;
      globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
    };
  }

  String staffId = "";

  List<Appointment> get present {
    if (state.showArchived) return docs;
    return docs.where((doc) => doc.archived != true).toList();
  }

  List<Appointment> get filtered {
    if (staffId.isEmpty) return present;
    return present.where((doc) => doc.operatorsIDs.contains(staffId)).toList();
  }

  List<String> get allPrescriptions {
    return Set<String>.from(present.expand((doc) => doc.prescriptions)).toList();
  }

  filterByStaff(String? value) {
    staffId = value ?? "";
    notify();
  }
}

final appointments = Appointments();
