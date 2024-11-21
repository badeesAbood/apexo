import 'dart:convert';

import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/i18/index.dart' as i18;
import 'package:apexo/state/admins.dart';
import 'package:apexo/state/backups.dart';
import 'package:apexo/state/permissions.dart';
import 'package:apexo/state/users.dart';

import '../../../backend/observable/save_local.dart';
import '../../../backend/observable/save_remote.dart';
import '../../../global_actions.dart';
import '../../state.dart';
import './settings_model.dart';
import '../../../backend/observable/store.dart';

const _storeNameGlobal = "settings_global";
const _storeNameLocal = "settings_local";

class GlobalSettings extends Store<Setting> {
  Map<String, String> defaults = {
    "currency_______": "USD",
    "phone__________": "1234567890",
    "permissions____": jsonEncode([false, true, true, true, false]),
    "start_day_of_wk": "monday",
  };

  GlobalSettings()
      : super(
          modeling: Setting.fromJson,
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
    state.activators[_storeNameGlobal] = () async {
      await loaded;

      local = SaveLocal(_storeNameGlobal);
      await loadFromLocal();

      remote = SaveRemote(
        pb: state.pb!,
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
          if (has(key) == false) {
            set(Setting.fromJson({"id": key, "value": value}));
          }
        });
      });

      globalActions.syncCallbacks[_storeNameGlobal] = () async {
        await Future.wait([
          synchronize(),
          admins.reloadFromRemote(),
          backups.reloadFromRemote(),
          users.reloadFromRemote(),
          permissions.reloadFromRemote()
        ]);
      };
      globalActions.reconnectCallbacks[_storeNameGlobal] = remote!.checkOnline;

      // setting services
      await Future.wait([
        admins.reloadFromRemote(),
        backups.reloadFromRemote(),
        users.reloadFromRemote(),
        permissions.reloadFromRemote()
      ]);
    };
  }
}

class LocalSettings extends ObservablePersistingObject {
  LocalSettings() : super(_storeNameLocal);

  String locale = "en";
  String dateFormat = "dd/MM/yyyy";

  init() {
    observe((ev) {
      final selectedLocaleIndex = i18.locale.list.indexWhere((l) => l.$code == locale);
      i18.locale.selectedIndex = selectedLocaleIndex == -1 ? 0 : selectedLocaleIndex;
      i18.locale.notify();
    });
  }

  @override
  fromJson(Map<String, dynamic> json) {
    locale = json["locale"] ?? locale;
    dateFormat = json["dateFormat"] ?? dateFormat;
  }

  @override
  Map<String, dynamic> toJson() {
    return {"locale": locale, "dateFormat": dateFormat};
  }
}

final globalSettings = GlobalSettings();
final localSettings = LocalSettings();
