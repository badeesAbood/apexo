import 'package:apexo/backend/utils/safe_dir.dart';
import 'package:hive_flutter/adapters.dart';

Future<void> safeHiveInit() async {
  try {
    await Hive.initFlutter();
  } catch (e) {
    Hive.init(baseDir);
  }
}
