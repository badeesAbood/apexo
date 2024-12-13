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
        state.setLoadingIndicator("Synchronizing appointments");
        await synchronize();
        globalActions.syncCallbacks[_storeName] = synchronize;
        globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
      };
    };
  }

  String doctorId = "";

  Map<String, Appointment> get filtered {
    if (doctorId.isEmpty) return present;
    return Map<String, Appointment>.fromEntries(
        present.entries.where((entry) => entry.value.operatorsIDs.contains(doctorId)));
  }

  List<String> get allPrescriptions {
    return Set<String>.from(present.values.expand((doc) => doc.prescriptions)).toList();
  }

  filterByDoctor(String? value) {
    doctorId = value ?? "";
    notify();
  }
}

final appointments = Appointments();
