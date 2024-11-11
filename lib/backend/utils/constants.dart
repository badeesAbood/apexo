import 'package:pocketbase/pocketbase.dart';

/// shared constants

const String alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
const String collectionName = "data";
final collectionImport = CollectionModel(
  name: collectionName,
  type: "base",
  schema: [
    SchemaField(
      name: "data",
      type: "json",
      options: {"maxSize": 2000000},
    ),
    SchemaField(
      name: "store",
      type: "text",
    ),
    SchemaField(name: "imgs", type: "file", options: {
      "maxSelect": 99,
      "maxSize": 5242880,
    }),
  ],
  indexes: [
    "CREATE INDEX `idx_get_since` ON `$collectionName` (\n  `store`,\n  `updated`\n)",
    "CREATE INDEX `idx_get_version` ON `$collectionName` (\n  `store`,\n  `updated` DESC\n)"
  ],
  listRule: "@request.auth.id != \"\"",
  viewRule: "@request.auth.id != \"\"",
  createRule: "@request.auth.id != \"\"",
  updateRule: "@request.auth.id != \"\" && store != \"settings_global\"",
  deleteRule: "@request.auth.id != \"\"",
);
