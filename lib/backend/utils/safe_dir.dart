import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const baseDir = 'apexo-files';

Future<String> filesDir() async {
  try {
    return join((await getApplicationDocumentsDirectory()).path, baseDir);
  } catch (e) {
    return baseDir;
  }
}
