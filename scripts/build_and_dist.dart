// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;
import "package:archive/archive.dart";

void main() {
  print("Will build dist for windows and publish the release...");

  // updating version tag
  final previousVersionTag = readPreviousVersion();
  print("Previous version: [$previousVersionTag]");
  var newVersionTag =
      prompt("What's the new version tag (make sure it is URL compatible, leave empty if you don't want to change)?")
          .trim();
  if (newVersionTag.isEmpty) newVersionTag = previousVersionTag;
  print("$previousVersionTag -> $newVersionTag");
  replaceVersion(previousVersionTag, newVersionTag);

  // Build windows application
  print("building for windows...");
  final res = Process.runSync(
    Platform.isWindows ? "flutter.bat" : "flutter",
    ["build", "windows", "--release"],
    workingDirectory: Directory.current.path,
    environment: Platform.environment,
  );
  print("   Finished building");
  print("   Exit code: ${res.exitCode}");
  print("   Err: ${res.stderr}");
  print("   OUT: ${res.stdout}");

  // packaging
  print("packaging...");
  final releaseDirPath = p.join(Directory.current.path, "build", "windows", "x64", "runner", "Release");
  final archivePath = p.join(Directory.current.path, "dist", "apexo_windows_$newVersionTag.zip");
  final archive = Archive();
  print("   package path: $archivePath");
  addDirectoryToArchive(releaseDirPath, archive);
  final zipFile = File(archivePath);
  final encoder = ZipEncoder();
  final zipData = encoder.encode(archive);
  print("   Writing to zip file...");
  zipFile.writeAsBytesSync(zipData!);
  print("   Finished packaging");

  // updating changelog
  final changes = prompt(
          "What are the changes? (separate lines by triple forward slash ///) leave empty if you don't wish to update the changelog.")
      .split("///");
  if (changes.join("").isNotEmpty) {
    appendChangeLog(newVersionTag, changes);
    print("Updated the changelog successfully");
  } else {
    print("Skipped updating the changelog");
  }
}

void addDirectoryToArchive(String directoryPath, Archive archive) {
  final directory = Directory(directoryPath);

  if (!directory.existsSync()) {
    throw Exception("Directory does not exist: $directoryPath");
  }

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File) {
      final file = entity;
      final fileContent = file.readAsBytesSync();

      final relativePath = file.path.substring(directory.path.length + 1);

      archive.addFile(ArchiveFile(relativePath, fileContent.length, fileContent));
    }
  }
}

String readPreviousVersion() {
  var file = File("lib/version.dart");
  if (!file.existsSync()) {
    return "";
  }
  return file.readAsStringSync().split("\"")[1];
}

replaceVersion(String oldV, String newV) {
  var file = File("lib/version.dart");
  var content = file.readAsStringSync();
  content = content.replaceAll(oldV, newV);
  file.writeAsStringSync(content);

  file = File("pubspec.yaml");
  content = file.readAsStringSync();
  content = content.replaceAll("version: $oldV+1", "version: $newV+1");
  file.writeAsStringSync(content);
}

String prompt(String message) {
  print("$message\n>");
  return stdin.readLineSync()!;
}

appendChangeLog(String versionTag, List<String> changes) {
  var file = File("CHANGELOG.md");
  var content = file.readAsStringSync();
  var changesStr = "\n-   ${changes.join("\n-   ")}";
  content = "$content\n### ____${versionTag}____\n$changesStr\n\n";
  file.writeAsStringSync(content);
}
