import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../state.dart';
import './settings_model.dart';
import '../../../backend/observable/store.dart';

const _storeNameGlobal = "settings_global_w";
const _storeNameLocal = "settings_local_w";

class GlobalSettings extends Store<Setting> {
  Map<String, String> defaults = {
    "currency": "\$",
    "phone": "1234567890",
  };

  GlobalSettings()
      : super(
          modeling: Setting.fromJson,
          local: SaveLocal("global_settings1"),
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
    state.activators[_storeNameGlobal] = (credentials) async {
      await loaded;

      final dbURL = credentials[0];
      final token = credentials[1];

      remote = SaveRemote(
        token: token,
        dbBranchUrl: dbURL,
        tableName: "main",
        store: _storeNameGlobal,
        onOnlineStatusChange: (current) {
          if (state.isOnline != current) {
            state.isOnline = current;
            state.notify();
          }
        },
      );

      state.setLoadingIndicator("Synchronizing settings");
      await Future.wait([loaded, synchronize()]).then((_) {
        defaults.forEach((key, value) {
          if (getIndex(key) == -1) {
            add(Setting.fromJson({"id": key, "value": value}));
          }
        });
      });

      globalActions.syncCallbacks[_storeNameGlobal] = synchronize;
      globalActions.reconnectCallbacks[_storeNameGlobal] = remote!.checkOnline;
    };
  }
}

class LocalSettings extends Store<Setting> {
  Map<String, String> defaults = {
    "locale": "english",
  };

  LocalSettings()
      : super(
          modeling: Setting.fromJson,
          local: SaveLocal(_storeNameLocal),
        ) {
    loaded.then((_) {
      defaults.forEach((key, value) {
        if (getIndex(key) == -1) {
          add(Setting.fromJson({"id": key, "value": value}));
        }
      });
    });
  }

  @override
  init() {
    super.init();
  }
}

final globalSettings = GlobalSettings();
final localSettings = LocalSettings();
