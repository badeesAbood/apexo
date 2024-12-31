import 'package:apexo/state/demo_generator.dart';

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
    state.activators[_storeName] = () async {
      await loaded;

      local = SaveLocal(_storeName);
      await deleteMemoryAndLoadFromPersistence();

      if (state.isDemo) {
        if (docs.isEmpty) setAll(demoLabworks(25));
      } else {
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
      }

      return () async {
        state.setLoadingIndicator("Synchronizing labworks");
        await synchronize();
        globalActions.syncCallbacks[_storeName] = synchronize;
        globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
      };
    };
  }

  List<String> get allLabs {
    Set<String> labs = {};
    for (var doc in docs.values) {
      labs.add(doc.lab);
    }
    return labs.toList();
  }

  List<String> get allPhones {
    Set<String> phones = {};
    for (var doc in docs.values) {
      phones.add(doc.phoneNumber);
    }
    return phones.toList();
  }

  String? getPhoneNumber(String lab) {
    for (var doc in docs.values) {
      if (doc.lab == lab) {
        return doc.phoneNumber;
      }
    }
    return null;
  }
}

final labworks = Labworks();
