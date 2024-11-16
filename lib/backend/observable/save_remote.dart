import 'dart:convert';
import 'dart:math';
import 'package:apexo/backend/utils/constants.dart';
import 'package:apexo/backend/utils/strip_id_from_file.dart';
import 'package:apexo/state/state.dart';
import 'package:http/http.dart' as http;
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
  final String store;
  final PocketBase pb;
  Timer? timer;

  void Function(bool)? onOnlineStatusChange;

  bool isOnline = true;
  SaveRemote({
    required this.store,
    required this.pb,
    this.onOnlineStatusChange,
  }) {
    checkOnline();
  }

  RecordService get remoteRows {
    return pb.collection(collectionName);
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
      await pb.health.check().timeout(const Duration(seconds: 3));
    } catch (e) {
      isOnline = false;
      retryConnection();
      onOnlineStatusChange!(isOnline);
      return;
    }
    isOnline = true;
    if (timer != null) {
      timer!.cancel();
    }
    onOnlineStatusChange!(isOnline);
  }

  Future<VersionedResult> getSince({int version = 0}) async {
    List<Row> result = [];

    final date = DateTime.fromMillisecondsSinceEpoch(version, isUtc: true).toIso8601String();
    bool nextPageExists = true;
    int currentPage = 1;

    do {
      try {
        final pageResult = await remoteRows.getList(
          filter: 'updated>"$date"&&store="$store"',
          sort: "updated",
          perPage: 900,
          page: currentPage,
        );

        for (var item in pageResult.items) {
          final ts = DateTime.parse(item.updated).millisecondsSinceEpoch;
          result.add(Row(id: item.id, data: jsonEncode(item.data["data"]), ts: ts));
          // handle uploaded images
          for (var img in item.data["imgs"]) {
            state.imagesToDownload.add("${state.url}/api/files/${item.collectionId}/${item.id}/$img");
          }
        }
        // trigger but don't wait for it to finish
        state.downloadImgs();

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
      final result = await remoteRows.getList(sort: "-updated", perPage: 1, filter: 'store="$store"');
      if (result.items.isEmpty) {
        return 0;
      }
      return DateTime.parse(result.items.first.updated).millisecondsSinceEpoch;
    } catch (e) {
      await checkOnline();
      throw Exception(e);
    }
  }

  Future<bool> put(List<RowToWriteRemotely> data) async {
    if (data.isEmpty) {
      return true;
    }

    // split data into chunks of 50
    List<List<RowToWriteRemotely>> chunks = [];
    for (int i = 0; i < data.length; i += 100) {
      chunks.add(data.sublist(i, i + 100 > data.length ? data.length : i + 900));
    }

    for (var chunk in chunks) {
      try {
        // TODO [Deferred]: currently pocketbase doesn't support upserts nor bulk upserts
        // once we have it in version 0.23 we should update the following code
        // splitting the data into chunks currently doesn't serve any purpose
        // but it's here for future use

        for (var item in chunk) {
          bool exists;
          try {
            await remoteRows.getOne(item.id);
            exists = true;
          } catch (e) {
            exists = false;
          }
          if (exists) {
            // update
            await remoteRows.update(item.id, body: {"data": item.data});
          } else {
            // create
            await remoteRows.create(body: {"store": store, "data": item.data, "id": item.id});
          }
        }
      } catch (e) {
        await checkOnline();
        rethrow;
      }
    }
    return true;
  }

  Future<bool> uploadImages(String recordID, List<String> paths) async {
    paths = paths.where((p) => p.isNotEmpty).toList();
    if (paths.isEmpty) {
      return true;
    }
    try {
      final alreadyUploaded = List<String>.from((await remoteRows.getOne(recordID, fields: "imgs")).data["imgs"])
          .map((e) => stripIDFromFileName(e));

      // upload files one by one to avoid having large request body
      for (final filePath in paths) {
        final filename = filePath.split('/').last;
        if (alreadyUploaded.contains(filename)) {
          continue;
        }
        final file = await http.MultipartFile.fromPath('imgs', filePath, filename: filename);
        await remoteRows.update(recordID, files: [file]);
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
}
