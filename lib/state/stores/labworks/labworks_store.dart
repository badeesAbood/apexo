import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../state/state.dart';
import './labwork_model.dart';
import '../../../backend/observable/store.dart';

const _storeName = "labworks";

class Labworks extends Store<Labwork> {
  Labworks()
      : super(
          modeling: Labwork.fromJson,
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

      state.setLoadingIndicator("Synchronizing labworks");
      await synchronize();

      globalActions.syncCallbacks[_storeName] = synchronize;
      globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
    };
  }

  List<Labwork> get present {
    if (state.showArchived) return docs;
    return docs.where((doc) => doc.archived != true).toList();
  }

  List<String> get allLabs {
    Set<String> labs = {};
    for (var doc in docs) {
      labs.add(doc.lab);
    }
    return labs.toList();
  }

  List<String> get allPhones {
    Set<String> phones = {};
    for (var doc in docs) {
      phones.add(doc.phoneNumber);
    }
    return phones.toList();
  }

  String? getPhoneNumber(String lab) {
    for (var doc in docs) {
      if (doc.lab == lab) {
        return doc.phoneNumber;
      }
    }
    return null;
  }
}

final labworks = Labworks();
