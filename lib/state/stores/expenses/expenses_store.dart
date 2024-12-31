import 'package:apexo/state/demo_generator.dart';

import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../state/state.dart';
import './expenses_model.dart';
import '../../../backend/observable/store.dart';

const _storeName = "expenses";

class Expenses extends Store<Expense> {
  Expenses()
      : super(
          modeling: Expense.fromJson,
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
        setAll(demoExpenses(300));
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
        state.setLoadingIndicator("Synchronizing expenses");
        await synchronize();
        globalActions.syncCallbacks[_storeName] = synchronize;
        globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
      };
    };
  }

  List<String> get allIssuers {
    Set<String> issuers = {};
    for (var doc in docs.values) {
      issuers.add(doc.issuer);
    }
    return issuers.toList();
  }

  List<String> get allTags {
    Set<String> tags = {};
    for (var doc in docs.values) {
      for (var tag in doc.tags) {
        tags.add(tag);
      }
    }
    return tags.toList();
  }

  List<String> get allItems {
    Set<String> items = {};
    for (var doc in docs.values) {
      for (var item in doc.items) {
        items.add(item);
      }
    }
    return items.toList();
  }

  List<String> get allPhones {
    Set<String> phones = {};
    for (var doc in docs.values) {
      phones.add(doc.phoneNumber);
    }
    return phones.toList();
  }

  String? getPhoneNumber(String issuer) {
    for (var doc in docs.values) {
      if (doc.issuer == issuer) {
        return doc.phoneNumber;
      }
    }
    return null;
  }
}

final expenses = Expenses();
