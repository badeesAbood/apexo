import 'package:pocketbase/pocketbase.dart';

/// shared constants

const String alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
const String dataCollectionName = "data";
const String publicCollectionName = "public";
const String webImagesStore = "web-images";
final dataCollectionImport = CollectionModel(
  name: dataCollectionName,
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
      "maxSize": 1048576 * 15, // 15MB
    }),
  ],
  indexes: [
    "CREATE INDEX `idx_get_since` ON `$dataCollectionName` (\n  `store`,\n  `updated`\n)",
    "CREATE INDEX `idx_get_version` ON `$dataCollectionName` (\n  `store`,\n  `updated` DESC\n)"
  ],
  listRule: ruleEitherLoggedOrSettings,
  viewRule: ruleEitherLoggedOrSettings,
  createRule: ruleLoggedUsersExceptForSettings,
  updateRule: ruleLoggedUsersExceptForSettings,
  deleteRule: ruleLoggedUsersExceptForSettings,
);

final publicCollectionImport = CollectionModel(
  name: "public",
  type: "view",
  listRule: "",
  viewRule: "",
  createRule: null,
  updateRule: null,
  deleteRule: null,
  options: {
    "query":
        "SELECT\n    data.id,\n    imgs,\n    json_extract(data.data, '\$.patientID') AS pid,\n    json_extract(data.data, '\$.date') AS date,\n    json_extract(data.data, '\$.prescriptions') AS prescriptions,\n    json_extract(data.data, '\$.price') AS price,\n    json_extract(data.data, '\$.paid') AS paid\nFROM data\nWHERE data.store = 'appointments';"
  },
);

const ruleLoggedUsersExceptForSettings = "@request.auth.id != \"\" && store != \"settings_global\"";
const ruleEitherLoggedOrSettings = "@request.auth.id != \"\" || store = \"settings_global\"";
