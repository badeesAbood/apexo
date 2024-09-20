import './member_model.dart';
import '../../state.dart';
import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../backend/observable/store.dart';

const _storeName = "staff";

class Staff extends Store<Member> {
  Staff()
      : super(
          modeling: Member.fromJson,
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

      state.setLoadingIndicator("Synchronizing staff members");
      await synchronize();

      globalActions.syncCallbacks[_storeName] = synchronize;
      globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
    };
  }

  List<Member> get presentAndOperate {
    return docs.where((doc) => doc.archived != true && doc.operates).toList();
  }

  List<Member> get present {
    return docs.where((doc) => doc.archived != true).toList();
  }

  bool showArchived = false;
  List<Member> get showing {
    if (showArchived) return docs;
    return present;
  }

  showArchivedChanged(bool? value) {
    showArchived = value ?? false;
    notify();
  }
}

final staff = Staff();
// don't forget to initialize it in main.dart
