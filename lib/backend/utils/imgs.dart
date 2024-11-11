import 'dart:io';
import 'package:apexo/backend/utils/strip_id_from_file.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

const baseDir = "apexo-images";

Future<Directory> _createDirectory(String path) async {
  final Directory dir = Directory(path);
  if (await dir.exists()) {
    return dir;
  } else {
    final Directory newDir = await dir.create(recursive: true);
    return newDir;
  }
}

Future<bool> _checkIfFileExists(String name) async {
  final appDir = await getApplicationDocumentsDirectory();
  final File file = File('${appDir.path}/$baseDir/$name');
  return await file.exists();
}

Future<File> _getOrCreateFile(String name) async {
  final appDir = await getApplicationDocumentsDirectory();
  await _createDirectory("${appDir.path}/$baseDir");
  return File('${appDir.path}/$baseDir/$name');
}

Future<ImageProvider> getImage(String name) async {
  if (await _checkIfFileExists(name)) {
    return Image.file(await _getOrCreateFile(name)).image;
  } else {
    return const AssetImage("assets/images/missing.png");
  }
}

Future<File> savePickedImage(XFile image) async {
  final File newImage = await _getOrCreateFile(image.name);
  if (await newImage.exists()) return newImage;
  return await File(image.path).copy(newImage.path);
}

Future<File> saveImageFromUrl(String imageUrl) async {
  final imageName = stripIDFromFileName(imageUrl.split('/').last);
  final File newImage = await _getOrCreateFile(imageName);
  if (await newImage.exists()) return newImage;

  final response = await http.get(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    return await newImage.writeAsBytes(response.bodyBytes);
  } else {
    throw Exception('Failed to download image');
  }
}
