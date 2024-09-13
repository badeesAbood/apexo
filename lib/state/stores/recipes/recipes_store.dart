import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../../state/state.dart';
import './recipes_model.dart';
import '../../../backend/observable/store.dart';

const _storeName = "recipes_w";

class Recipes extends Store<Recipe> {
  Recipes()
      : super(
          modeling: Recipe.fromJson,
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

      state.setLoadingIndicator("Synchronizing recipes");
      await synchronize();

      globalActions.syncCallbacks[_storeName] = synchronize;
      globalActions.reconnectCallbacks[_storeName] = remote!.checkOnline;
    };
  }

  bool showArchived = false;
  List<Recipe> get present {
    if (showArchived) return recipes.docs;
    return [...recipes.docs].where((doc) => doc.archived != true).toList();
  }

  showArchivedChanged(bool? value) {
    showArchived = value ?? false;
    notify();
  }
}

final recipes = Recipes();
