import 'package:apexo/backend/observable/observable.dart';
import 'package:apexo/backend/observable/save_local.dart';
import 'package:apexo/state/state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http_parser/http_parser.dart';

class BackupFile {
  late String key;
  late int size;
  late DateTime date;
  BackupFile(BackupFileInfo info) {
    key = info.key;
    size = info.size;
    date = DateTime.parse(info.modified);
  }
}

class Backups extends ObservableObject {
  List<BackupFile> list = [];
  bool loaded = false;
  bool loading = false;
  bool creating = false;
  bool uploading = false;
  Map<String, bool> downloading = {};
  Map<String, bool> deleting = {};
  Map<String, bool> restoring = {};

  Future<void> newBackup() async {
    creating = true;
    notify();
    await state.pb!.backups.create("");
    await reloadFromRemote();
    creating = false;
    notify();
  }

  Future<void> delete(String key) async {
    deleting.addAll({key: true});
    notify();
    await state.pb!.backups.delete(key);
    deleting.remove(key);
    await reloadFromRemote();
  }

  Future<Uri> downloadUri(String key) async {
    downloading.addAll({key: true});
    notify();
    final token = await state.pb!.files.getToken();
    downloading.remove(key);
    notify();
    return state.pb!.backups.getDownloadUrl(token, key);
  }

  Future<void> restore(String key) async {
    restoring.addAll({key: true});
    notify();
    await state.pb!.backups.restore(key);
    await Future.wait(removeAllLocalData.map((e) => e()));
    restoring.remove(key);
    notify();
    state.logout();
  }

  Future<void> pickAndUpload() async {
    final filePickerRes = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: ["zip"],
      withReadStream: true,
      allowCompression: true,
      type: FileType.custom,
    );
    if (filePickerRes == null) {
      return;
    }
    if (filePickerRes.files.isEmpty) {
      return;
    }
    final file = filePickerRes.files.first;
    final multipartFile = MultipartFile(
      "file",
      file.readStream!,
      file.size,
      filename: "uploaded-${DateTime.now().millisecondsSinceEpoch}-" + file.name,
      contentType: MediaType("application", "zip"),
    );
    uploading = true;
    notify();
    await state.pb!.backups.upload(multipartFile);
    uploading = false;
    notify();
    await reloadFromRemote();
  }

  Future<void> reloadFromRemote() async {
    if (state.isAdmin == false || state.pb == null || state.token.isEmpty || state.pb!.authStore.isValid == false) {
      return;
    }
    loading = true;
    notify();
    list = (await state.pb!.backups.getFullList()).map((e) => BackupFile(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    loaded = true;
    loading = false;
    notify();
  }
}

final backups = Backups();
