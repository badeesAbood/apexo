import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:apexo/backend/utils/imgs.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:mime/mime.dart';

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
  /// https://[workspace].[region].xata.sh/db/[db]:[branch]
  final String dbBranchUrl;
  final String token;
  final String tableName;
  final String store;
  Timer? timer;

  void Function(bool)? onOnlineStatusChange;

  bool isOnline = true;
  SaveRemote({
    required this.dbBranchUrl,
    required this.token,
    required this.store,
    required this.tableName,
    this.onOnlineStatusChange,
  }) {
    checkOnline();
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
      await http.get(Uri.parse(dbBranchUrl), headers: {"Authorization": "Bearer $token"});
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

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(version, isUtc: true);
    String formattedDate = dateTime.toIso8601String();
    var cursor = "";

    do {
      final url = '$dbBranchUrl/tables/$tableName/query';
      http.Response response;
      try {
        response = (await http.post(Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': "application/json",
            },
            body: jsonEncode({
              "columns": ["id", "data", "xata.updatedAt", "imgs"],
              if (cursor.isEmpty)
                "filter": {
                  "store": store,
                  "xata.updatedAt": {"\$gt": formattedDate}
                },
              "page": {
                "size": 15,
                if (cursor.isNotEmpty) "after": cursor,
              }
            })));
      } catch (e) {
        await checkOnline();
        rethrow;
      }

      if (response.statusCode > 299) {
        throw response.body;
      }

      Map<String, dynamic> queryResult = jsonDecode(utf8.decode(response.bodyBytes));

      List rows = queryResult["records"];

      // handle uploaded images
      for (var r in rows) {
        for (var img in r["imgs"]) {
          await saveImageFromUrl(img["url"], img["name"]);
        }
      }

      Iterable<Row> formattedRows = rows.map((row) =>
          Row(id: row["id"], data: row["data"], ts: DateTime.parse(row["xata"]["updatedAt"]).millisecondsSinceEpoch));
      result.addAll(formattedRows);

      if (queryResult["meta"]["page"]["more"]) {
        cursor = queryResult["meta"]["page"]["cursor"];
      } else {
        cursor = "";
        break;
      }
    } while (cursor.isNotEmpty);

    return VersionedResult(result.isNotEmpty ? result.map((r) => r.ts).reduce(max) : 0, result);
  }

  Future<int> getVersion() async {
    final url = '$dbBranchUrl/tables/$tableName/query';

    http.Response response;
    try {
      response = (await http.post(Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': "application/json",
          },
          body: jsonEncode({
            "columns": ["xata"],
            "filter": {
              "store": store,
            },
            "sort": {"xata.updatedAt": "desc"},
            "page": {"size": 1}
          })));
    } catch (e) {
      await checkOnline();
      throw Exception(e);
    }

    if (response.statusCode > 299) {
      throw Exception(response.body);
    }

    Map<String, dynamic> queryResult = jsonDecode(response.body);
    List rows = queryResult["records"];
    if (rows.isEmpty) {
      return 0;
    }
    return DateTime.parse(rows[0]["xata"]["updatedAt"]).millisecondsSinceEpoch;
  }

  Future<bool> put(List<RowToWriteRemotely> data) async {
    final url = '$dbBranchUrl/transaction';

    http.Response response;
    try {
      response = (await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': "application/json",
        },
        body: jsonEncode({
          "operations": data.map((r) {
            return {
              "update": {
                "table": tableName,
                "id": r.id,
                "fields": {
                  "store": store,
                  "data": r.data,
                },
                "upsert": true
              }
            };
          }).toList(),
        }),
      ));
    } catch (e) {
      await checkOnline();
      rethrow;
    }

    if (response.statusCode > 299) {
      throw response.body;
    }
    return true;
  }

  Future<bool> uploadImages(String rowID, List<String> paths) async {
    print(paths);
    print("-----------------");
    final files = paths.map((p) => File(p)).toList();
    final filenames = paths.map((p) => p.split('/').last).toList();
    final url = '$dbBranchUrl/tables/$tableName/data/$rowID';

    http.Response response;
    try {
      // get older files
      final olderFiles = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      final olderIds = jsonDecode(olderFiles.body)["imgs"].map((e) => e["id"]).toList();

      // Read the file content as bytes
      final filesBytes = await Future.wait(files.map((file) => file.readAsBytes()).toList());
      final base64Strings = filesBytes.map((bytes) => base64Encode(bytes)).toList();
      final mimeTypes = files.map((file) => lookupMimeType(file.path) ?? "application/octet-stream").toList();

      final List<Map<String, String>> newFiles = [];

      for (int i = 0; i < files.length; i++) {
        newFiles.add({
          "base64Content": base64Strings[i],
          "name": filenames[i],
          "mediaType": mimeTypes[i],
        });
      }

      // Send the PUT request
      response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "imgs": [
            ...olderIds.map((id) => {"id": id}),
            ...newFiles,
          ]
        }),
      );
    } catch (e) {
      await checkOnline();
      rethrow;
    }

    if (response.statusCode > 299) {
      throw response.body;
    }
    return true;
  }

  Future<bool> deleteImages(String rowID, List<String> paths) async {
    final filenames = paths.map((p) => p.split('/').last).toList();
    final url = '$dbBranchUrl/tables/$tableName/data/$rowID';

    http.Response response;
    try {
      // get older files
      final uploaded = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      final uploadedMetadata = jsonDecode(uploaded.body)["imgs"].toList();
      final keepMetadata = uploadedMetadata.where((m) => !filenames.contains(m["name"])).toList();

      // Send the PATCH request
      response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "imgs": [
            ...keepMetadata.map((metadata) => {"id": metadata["id"]}),
          ]
        }),
      );
    } catch (e) {
      await checkOnline();
      rethrow;
    }

    if (response.statusCode > 299) {
      throw response.body;
    }
    return true;
  }

  Future<bool> clear() async {
    final url = '$dbBranchUrl/sql';
    http.Response response;
    try {
      response = await http.post(Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': "application/json",
          },
          body: jsonEncode({
            "statement": "DELETE FROM $tableName WHERE store = '$store'",
          }));
    } catch (e) {
      await checkOnline();
      rethrow;
    }
    if (response.statusCode > 299) {
      throw response.body;
    }
    return true;
  }
}
