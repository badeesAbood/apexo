import 'package:apexo/backend/utils/constants.dart';
import 'package:pocketbase/pocketbase.dart';

/// This would initialize the server creating required collections, rules, and settings
initializePocketbase(PocketBase pb) async {
  await pb.collections.import([dataCollectionImport, publicCollectionImport]);
  await pb.collections.update("users", body: {"createRule": null});
  await pb.settings.update(body: {
    "batch": {"enabled": true, "maxRequests": 101, "timeout": 3, "maxBodySize": 0}
  });
}
