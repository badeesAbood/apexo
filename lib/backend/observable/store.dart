import 'dart:async';
import 'dart:convert';
import 'package:apexo/backend/utils/constants.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/state/state.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart';

import 'model.dart';
import 'observable.dart';
import 'save_local.dart';
import 'save_remote.dart';
import '../utils/Debouncer.dart';

typedef ModellingFunc<G> = G Function(Map<String, dynamic> input);

class SyncResult {
  int? pushed;
  int? pulled;
  int? conflicts;
  String? exception;
  SyncResult({this.pushed, this.pulled, this.conflicts, this.exception});
  @override
  toString() {
    return "pushed: $pushed, pulled: $pulled, conflicts: $conflicts, exception: $exception";
  }
}

/// A class that represents a store of documents
/// This implements observableDict
/// but adds ability to persist data as well as synchronize it with a remote server
// ignore: slash_for_doc_comments
/**
      ----------------                              ----------------
      |              |                              |              |
      |    Remote    | <----> ObservableDict <----> |    Local     |
      |  saveRemote  |                              |  saveLocal   |
      ----------------                              ----------------
 */

class Store<G extends Model> {
  late Future<void> loaded;
  final Function? onSyncStart;
  final Function? onSyncEnd;
  final ObservableDict<G> observableObject;
  final Set<String> changes = {};
  SaveLocal? local;
  SaveRemote? remote;
  Future<void> Function()? realtimeSub;
  final int debounceMS;
  late Debouncer _debouncer;
  late ModellingFunc<G> modeling;
  bool deferredPresent = false;
  int lastProcessChanges = 0;
  bool? manualSyncOnly;

  Store({
    required this.modeling,
    this.local,
    this.remote,
    this.debounceMS = 100,
    this.onSyncStart,
    this.onSyncEnd,
    this.manualSyncOnly,
  }) : observableObject = ObservableDict() {
    // setting up debouncer
    _debouncer = Debouncer(
      milliseconds: debounceMS,
    );

    // loading from local
    loaded = deleteMemoryAndLoadFromPersistence();
  }

  @mustCallSuper
  void init() {
    // setting up observers
    observableObject.observe((events) {
      if (events[0].type == EventType.modify && events[0].id == "__ignore_view__") {
        // this is a view change not a storage change
        return;
      }
      List<String> ids = events.map((e) => e.id).toList();
      changes.addAll(ids);
      _debouncer.run(() {
        _processChanges();
      });
    });
  }

  /// reloads the store from the local database
  /// DO NOT USE THIS METHOD UNLESS YOU'RE SURE THAT THERE ARE NO CHANGES PENDING TO BE SAVED
  /// use "reload" method instead
  Future<void> deleteMemoryAndLoadFromPersistence() async {
    if (local == null) {
      return;
    }
    Iterable<String> all = await local!.getAll();
    Iterable<G> modeled = all.map((x) => modeling(_deSerialize(x)));
    // silent for persistence
    observableObject.silently(() {
      observableObject.clear();
      observableObject.setAll(modeled.toList());
    });
    // but loud for view
    observableObject.notifyView();
    return;
  }

  String _serialize(G input) {
    return jsonEncode(input);
  }

  Map<String, dynamic> _deSerialize(String input) {
    return jsonDecode(input);
  }

  _processChanges() async {
    if (local == null) {
      return;
    }

    if (changes.isEmpty) return;
    if (observableObject.docs.isEmpty) return;
    onSyncStart?.call();
    lastProcessChanges = DateTime.now().millisecondsSinceEpoch;

    Map<String, String> toWrite = {};
    Map<String, int> toDefer = {};
    List<String> changesToProcess = [...changes];

    for (String element in changesToProcess) {
      G? item = observableObject.get(element);
      if (item == null) {
        changes.remove(element);
        continue;
      }
      String serialized = _serialize(item);
      toWrite[element] = serialized;
      toDefer[element] = lastProcessChanges;
    }

    await local!.put(toWrite);
    Map<String, int> lastDeferred = await local!.getDeferred();

    if (remote == null) {
      changes.clear();
      onSyncEnd?.call();
      return;
    }

    if (remote!.isOnline && lastDeferred.isEmpty) {
      try {
        await remote!.put(toWrite.entries.map((e) => RowToWriteRemotely(id: e.key, data: e.value)).toList());
        changes.clear();
        onSyncEnd?.call();
        // while we have the connection lets synchronize
        // don't put "await" before synchronize() since we don't want catch the error
        // if it gets caught it means the same file will be placed in deferred
        if (manualSyncOnly != true) {
          // this condition is especially helpful during testing
          // to have fine grained control over synchronization steps
          synchronize();
        }
        return;
      } catch (e, s) {
        logger("Error during sending (Will defer updates): $e", s);
      }
    }

    /**
	 * If we reached here, it means that its either
	 * 1. we're offline
	 * 2. there was an error during sending updates
	 * 3. there are already deferred updates
	 */
    await local!.putDeferred({}
      ..addAll(lastDeferred)
      ..addAll(toDefer));
    deferredPresent = true;
    changes.clear();
    onSyncEnd?.call();
  }

  Future<SyncResult> _syncTry() async {
    if (local == null || remote == null) {
      return SyncResult(exception: "local/remote persistence layers are not defined");
    }

    if (remote!.isOnline == false) return SyncResult(exception: "remote server is offline");
    try {
      int localVersion = await local!.getVersion();
      int remoteVersion = await remote!.getVersion();

      Map<String, int> deferred = await local!.getDeferred();
      int conflicts = 0;

      if (localVersion == remoteVersion && deferred.isEmpty) {
        return SyncResult(exception: "nothing to sync");
      }

      // fetch updates since our local version
      VersionedResult remoteUpdates = await remote!.getSince(version: localVersion);

      List<int> remoteLosersIndices = [];

      // check conflicts: last write wins
      deferred.removeWhere((dfID, deferredTimeStamp) {
        int remoteConflictIndex = remoteUpdates.rows.indexWhere((r) => r.id == dfID);
        if (remoteConflictIndex == -1) {
          // no conflict
          return false;
        }
        int remoteTimeStamp = remoteUpdates.rows[remoteConflictIndex].ts;
        if (deferredTimeStamp > remoteTimeStamp) {
          // local update wins
          conflicts++;
          remoteLosersIndices.add(remoteConflictIndex);
          return false;
        } else {
          // remote update wins
          // return true to remove this item from deferred
          conflicts++;
          return true;
        }
      });

      // remove losers from remote updates
      // Sort indices in descending order
      remoteLosersIndices.sort((a, b) => b.compareTo(a));
      for (int index in remoteLosersIndices) {
        remoteUpdates.rows.removeAt(index);
      }

      Map<String, String> toLocalWrite = Map.fromEntries(remoteUpdates.rows.map((r) => MapEntry(r.id, r.data)));

      // those will be built in the for loop below
      Map<String, String> toRemoteWrite = {};
      Map<String, List<String>> toUploadFiles = {};
      Map<String, List<String>> toRemoveFiles = {};

      for (var entry in deferred.entries) {
        if (entry.key.startsWith("FILE")) {
          List<String> deferredFile = entry.key.split("||");
          if (deferredFile[1] == "R") {
            if (!toRemoveFiles.containsKey(deferredFile[2])) {
              toRemoveFiles[deferredFile[2]] = [];
            }
            toRemoveFiles[deferredFile[2]]!.addAll(deferredFile[3].split("#"));
          } else {
            if (!toUploadFiles.containsKey(deferredFile[2])) {
              toUploadFiles[deferredFile[2]] = [];
            }
            toUploadFiles[deferredFile[2]]!.addAll(deferredFile[3].split("#"));
          }
        } else {
          toRemoteWrite.addAll({entry.key: await local!.get(entry.key)});
        }
      }

      if (toLocalWrite.isNotEmpty) {
        await local!.put(toLocalWrite);
      }
      if (toRemoteWrite.isNotEmpty) {
        await remote!.put(toRemoteWrite.entries.map((e) => RowToWriteRemotely(id: e.key, data: e.value)).toList());
      }
      if (toUploadFiles.isNotEmpty) {
        for (var element in toUploadFiles.entries) {
          await remote!.uploadImages(
              element.key,
              await Future.wait(
                  element.value.map((path) => MultipartFile.fromPath("imgs", path, filename: path.split("/").last))));
        }
      }
      if (toRemoveFiles.isNotEmpty) {
        for (var element in toRemoveFiles.entries) {
          await remote!.deleteImages(element.key, element.value);
        }
      }

      // reset deferred
      await local!.putDeferred({});
      deferredPresent = false;

      // set local version to the version given by the current request
      // this might be outdated as soon as this functions ends
      // that's why this function will run on a while loop (below)
      await local!.putVersion(remoteUpdates.version);

      // but if we had deferred updates then the remoteUpdates.version is outdated
      // so we need to fetch the latest version again
      // however, we should not do this in the same run since there might be updates
      // from another client between the time we fetched the remoteUpdates and the
      // time we sent deferred updates
      // so every sync should be followed by another sync
      // until the versions match
      // this is why there's another sync method below

      await deleteMemoryAndLoadFromPersistence();
      return SyncResult(
          pulled: toLocalWrite.length, pushed: toRemoteWrite.length, conflicts: conflicts, exception: null);
    } catch (e, s) {
      logger("Error during synchronization: $e", s);
      return SyncResult(exception: e.toString());
    }
  }

  //// ----------------------------- Public API --------------------------------

  /// Syncs the local database with the remote database
  Future<List<SyncResult>> synchronize() async {
    // on first sync, we need to set up the realtime subscription
    if (remote != null && realtimeSub == null && manualSyncOnly != true) {
      try {
        realtimeSub = await remote?.pbInstance.collection(dataCollectionName).subscribe("*", (msg) {
          if (msg.record?.data["store"] == remote?.storeName) {
            synchronize();
          }
        });
        state.onOnline[remote!.storeName] = () {
          synchronize();
        };
        state.onOffline[remote!.storeName] = () {
          if (realtimeSub != null) {
            // cancel the subscription once we go offline
            realtimeSub!();
            // and set this to null so that we get to subscribe again when we go online
            realtimeSub = null;
          }
        };
      } catch (e, s) {
        logger("Error during realtime subscription: $e", s);
      }
    }

    lastProcessChanges = DateTime.now().millisecondsSinceEpoch;
    onSyncStart?.call();
    List<SyncResult> tries = [];
    while (true) {
      SyncResult result = await _syncTry();
      tries.add(result);
      if (result.exception != null) break;
    }
    onSyncEnd?.call();
    return tries;
  }

  //// Returns true if the local database is in sync with the remote database
  Future<bool> inSync() async {
    try {
      if (local == null || remote == null) return false;
      if (deferredPresent) return false;
      return await local!.getVersion() == await remote!.getVersion();
    } catch (e, s) {
      logger("Error during inSync check: $e", s);
      return false;
    }
  }

  /// Reloads the store from the local database
  Future<void> reload() async {
    // wait for any changes to be processed, since we're going to delete the dictionary
    await Future.delayed(Duration(milliseconds: debounceMS + 2));
    await deleteMemoryAndLoadFromPersistence();
  }

  /// Returns a list of all the documents in the local database
  Map<String, G> get docs {
    return Map<String, G>.unmodifiable(observableObject.docs);
  }

  Map<String, G> get present {
    return Map<String, G>.fromEntries(docs.entries
        .where((entry) => (state.showArchived || entry.value.archived != true) && entry.value.locked != true));
  }

  bool has(String id) {
    return observableObject.docs.containsKey(id);
  }

  /// gets a document by id
  G? get(String id) {
    return observableObject.docs[id];
  }

  /// adds a document
  void set(G item) {
    observableObject.set(item);
  }

  /// adds a list of documents
  void setAll(List<G> items) {
    observableObject.setAll(items);
  }

  /// archives a document by id (the concept of deletion is not supported here)
  void archive(String id) {
    G? item = get(id);
    if (item == null) return;
    observableObject.set(item..archived = true);
  }

  /// un-archives a document by id (the concept of deletion is not supported here)
  void unarchive(String id) {
    G? item = get(id);
    if (item == null) return;
    observableObject.set(item..archived = false);
  }

  /// archives a document by id (the concept of deletion is not supported here)
  void delete(String id) {
    archive(id);
  }

  /// upload set of files to a certain row
  Future<void> uploadImgs(String rowID, List<String> paths, [bool upload = true]) async {
    onSyncStart?.call();
    if (remote == null) throw Exception("remote persistence layer is not defined");
    if (local == null) throw Exception("local persistence layer is not defined");

    Map<String, int> lastDeferred = await local!.getDeferred();

    if (remote!.isOnline && lastDeferred.isEmpty) {
      try {
        if (upload) {
          await remote!.uploadImages(
              rowID,
              await Future.wait(
                  paths.map((path) => MultipartFile.fromPath("imgs", path, filename: path.split("/").last))));
        } else {
          await remote!.deleteImages(rowID, paths);
        }
        onSyncEnd?.call();
        synchronize();
        return;
      } catch (e, s) {
        logger("Error during sending the file (Will defer upload): $e", s);
      }
    }

    /**
     * If we reached here it means that its either
     * 1. we're offline
     * 2. there was an error during sending updates
     * 3. there are already deferred updates
     */
    // DEFERRED Structure: "FILE||{U or R}||{rowID}||path1#path2#path3"
    await local!.putDeferred({}
      ..addAll(lastDeferred)
      ..addAll({"FILE||${upload ? "U" : "R"}||$rowID||${paths.join("#")}": 0}));
    deferredPresent = true;
    onSyncEnd?.call();
  }

  /// notifies the view that the store has changed
  void notify() {
    observableObject.notifyView();
  }

  Future<void> waitUntilChangesAreProcessed() async {
    await Future.delayed(Duration(milliseconds: debounceMS + 2));
    while (changes.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }
}
