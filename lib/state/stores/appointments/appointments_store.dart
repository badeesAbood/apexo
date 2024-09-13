import '../../../backend/observable/observable.dart';
import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../state/state.dart';
import './appointment_model.dart';
import '../../../backend/observable/store.dart';

const _storeName = "appointments_w";

class Appointments extends Store<Appointment> {
  Appointments()
      : super(
          modeling: Appointment.fromJson,
          local: SaveLocal(_storeName),
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

  ObservableState<bool> showArchived = ObservableState(false);
  List<Appointment> get present {
    if (showArchived()) return appointments.docs;
    return appointments.docs.where((doc) => doc.archived != true).toList();
  }

  showArchivedChanged(bool? value) {
    showArchived(value ?? false);
    //notify();
  }
}

final appointments = Appointments();
