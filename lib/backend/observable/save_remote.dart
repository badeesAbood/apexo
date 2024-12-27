import 'dart:convert';
import 'dart:math';
import 'package:apexo/backend/utils/constants.dart';
import 'package:apexo/backend/utils/logger.dart';
import 'package:apexo/backend/utils/strip_id_from_file.dart';
import 'package:apexo/state/state.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:pocketbase/pocketbase.dart';

class RowToWriteRemotely {
  String id;
  String data;
  String store = "";
  RowToWriteRemotely({required this.id, required this.data});
  toJson() {
    return {
      "id": id,
      "data": data,
      "store": store,
    };
  }
}

class Row extends RowToWriteRemotely {
  int ts;
  Row({required super.id, required super.data, required this.ts});
}

class VersionedResult {
  int version;
  List<Row> rows;
  VersionedResult(this.version, this.rows);
}

class SaveRemote {
  final String storeName;
  final PocketBase pbInstance;

  // timer to debounce online status checks
  Timer? timer;

  // callback to notify the app of online status changes
  void Function(bool)? onOnlineStatusChange;

  bool isOnline = true;
  SaveRemote({
    required this.storeName,
    required this.pbInstance,
    this.onOnlineStatusChange,
  }) {
    checkOnline();
  }

  RecordService get remoteRows {
    return pbInstance.collection(dataCollectionName);
  }

  void retryConnection() {
    if (timer != null && timer!.isActive) {
      return;
    }
    Timer.periodic(const Duration(seconds: 5), (t) {
      timer = t;
      if (isOnline) {
        timer!.cancel();
      } else {
        checkOnline();
      }
    });
  }

  Future<void> checkOnline() async {
    try {
      await pbInstance.health.check().timeout(const Duration(seconds: 3));
    } catch (e) {
      isOnline = false;
      retryConnection();
      if (onOnlineStatusChange != null) onOnlineStatusChange!(isOnline);
      return;
    }
    isOnline = true;
    if (timer != null) {
      timer!.cancel();
    }
    if (onOnlineStatusChange != null) onOnlineStatusChange!(isOnline);
  }

  String formatForPocketBase(int input) {
    // for some reason, pocketbase doesn't accept the ISO8601 format
    // it stores "updated" and "created" fields in the following format: "2024-11-28 12:00:00.000Z"
    // and it disregards the time if a "T" was included in the comparison
    // this format is the more preferable one for pocketbase
    // This behavior is deeply rooted in SQLite: https://www.sqlite.org/lang_datefunc.html
    return "${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.fromMillisecondsSinceEpoch(input, isUtc: true))}Z";
  }

  Future<VersionedResult> getSince({int version = 0}) async {
    List<Row> result = [];

    final date = formatForPocketBase(version);
    bool nextPageExists = true;
    int currentPage = 1;

    do {
      try {
        final pageResult = await remoteRows.getList(
          filter: 'updated>"$date"&&store="$storeName"',
          sort: "updated",
          perPage: 900,
          page: currentPage,
          fields: "data,id,updated,imgs",
        );

        for (var item in pageResult.items) {
          final ts = DateTime.parse(item.get<String>("updated")).millisecondsSinceEpoch;
          result.add(Row(id: item.id, data: jsonEncode(item.data["data"]), ts: ts));
          fullNamesCache.addAll({item.id: List<String>.from(item.data["imgs"])});
        }

        // handle pagination
        if (pageResult.totalPages > currentPage) {
          currentPage++;
        } else {
          nextPageExists = false;
        }
      } catch (e) {
        await checkOnline();
        rethrow;
      }
    } while (nextPageExists);

    return VersionedResult(result.isNotEmpty ? result.map((r) => r.ts).reduce(max) : 0, result);
  }

  Future<int> getVersion() async {
    try {
      final result =
          await remoteRows.getList(sort: "-updated", perPage: 1, filter: 'store="$storeName"', fields: "updated");
      if (result.items.isEmpty) {
        return 0;
      }
      return DateTime.parse(result.items.first.get<String>("updated")).millisecondsSinceEpoch;
    } catch (e) {
      await checkOnline();
      throw Exception(e);
    }
  }

  Future<bool> put(List<RowToWriteRemotely> data) async {
    if (data.isEmpty) {
      return true;
    }

    // split data into chunks of 100
    List<List<RowToWriteRemotely>> chunks = [];
    for (var i = 0; i < data.length; i += 100) {
      chunks.add(data.sublist(i, min(i + 100, data.length)));
    }

    for (var chunk in chunks) {
      try {
        final batchOperation = pbInstance.createBatch();
        for (var item in chunk) {
          batchOperation
              .collection(dataCollectionName)
              .upsert(body: {"store": storeName, "data": item.data, "id": item.id});
        }
        await batchOperation.send();
      } catch (e) {
        await checkOnline();
        rethrow;
      }
    }
    return true;
  }

  Future<bool> uploadImages(String recordID, List<http.MultipartFile> files) async {
    try {
      late List<String> alreadyUploaded;
      try {
        alreadyUploaded = List<String>.from((await remoteRows.getOne(recordID, fields: "imgs")).data["imgs"])
            .map((e) => stripIDFromFileName(e))
            .toList();
      } catch (e, s) {
        alreadyUploaded = [];
        logger("Error while trying to get a list of uploaded images: $e", s);
      }

      // upload files one by one to avoid having large request body
      for (final file in files) {
        // skip if file was already uploaded
        if (alreadyUploaded
            .where((uploaded) => uploaded.contains((file.filename ?? "null").split(".").first))
            .isNotEmpty) {
          continue;
        }
        alreadyUploaded.add(file.filename ?? "null");
        final updatedRecord = await remoteRows.update(recordID, files: [file], fields: "imgs");
        fullNamesCache.addAll({recordID: List<String>.from(updatedRecord.data["imgs"])});
      }
    } catch (e) {
      await checkOnline();
      rethrow;
    }
    return true;
  }

  Future<bool> deleteImages(String rowID, List<String> paths) async {
    try {
      final allFullNames = List<String>.from((await remoteRows.getOne(rowID, fields: "imgs")).data["imgs"]);
      final allLocalNames = allFullNames.map((e) => stripIDFromFileName(e)).toList();
      final localNamesToDelete = paths.map((e) => e.split("/").last);
      List<String> fullNamesToDelete = [];
      for (var i = 0; i < allLocalNames.length; i++) {
        final localName = allLocalNames[i];
        if (localNamesToDelete.contains(localName)) {
          fullNamesToDelete.add(allFullNames[i]);
        }
      }
      if (fullNamesToDelete.isEmpty) {
        return true;
      }
      await remoteRows.update(rowID, body: {
        "imgs-": fullNamesToDelete,
      });
    } catch (e) {
      await checkOnline();
      rethrow;
    }
    return true;
  }

  Future<String?> getImageLink(String rowID, String imageName) async {
    try {
      List<String> fullNames;
      if (fullNamesCache.containsKey(rowID)) {
        fullNames = fullNamesCache[rowID]!;
      } else {
        final record = await remoteRows.getOne(rowID, fields: "imgs");
        fullNames = List<String>.from(record.data["imgs"]);
      }
      fullNamesCache[rowID] = fullNames;
      final candidates = fullNames.where((e) => e.contains(imageName.split(".").first)).toList();
      if (candidates.isEmpty) {
        return null;
      } else {
        return "${state.url}/api/files/$dataCollectionName/$rowID/${candidates.first}";
      }
    } catch (e) {
      await checkOnline();
      rethrow;
    }
  }

  Map<String, List<String>> fullNamesCache = {};
}
