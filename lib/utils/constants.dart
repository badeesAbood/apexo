import 'package:pocketbase/pocketbase.dart';

/// shared constants

const String alphabet = "abcdefghijklmnopqrstuvwxyz0123456789";
const String dataCollectionName = "data";
const String publicCollectionName = "public";
const String webImagesStore = "web-images";
final dataCollectionImport = CollectionModel(
  name: dataCollectionName,
  type: "base",
  fields: [
    CollectionField({
      "autogeneratePattern": "[a-z0-9]{15}",
      "hidden": false,
      "max": 15,
      "min": 15,
      "name": "id",
      "pattern": "^[a-zA-Z0-9_]+\$",
      "presentable": false,
      "primaryKey": true,
      "required": true,
      "system": true,
      "type": "text"
    }),
    CollectionField({
      "hidden": false,
      "maxSize": 2000000,
      "name": "data",
      "presentable": false,
      "required": false,
      "system": false,
      "type": "json"
    }),
    CollectionField({
      "autogeneratePattern": "",
      "hidden": false,
      "max": 0,
      "min": 0,
      "name": "store",
      "pattern": "",
      "presentable": false,
      "primaryKey": false,
      "required": false,
      "system": false,
      "type": "text"
    }),
    CollectionField({
      "hidden": false,
      "maxSelect": 99,
      "maxSize": 15728640,
      "mimeTypes": null,
      "name": "imgs",
      "presentable": false,
      "protected": false,
      "required": false,
      "system": false,
      "thumbs": null,
      "type": "file"
    }),
    CollectionField({
      "hidden": false,
      "name": "created",
      "onCreate": true,
      "onUpdate": false,
      "presentable": false,
      "system": false,
      "type": "autodate"
    }),
    CollectionField({
      "hidden": false,
      "name": "updated",
      "onCreate": true,
      "onUpdate": true,
      "presentable": false,
      "system": false,
      "type": "autodate"
    })
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
  viewQuery:
      "SELECT\n    data.id,\n    imgs,\n    json_extract(data.data, '\$.patientID') AS pid,\n    json_extract(data.data, '\$.date') AS date,\n    json_extract(data.data, '\$.prescriptions') AS prescriptions,\n    json_extract(data.data, '\$.price') AS price,\n    json_extract(data.data, '\$.paid') AS paid\nFROM data\nWHERE data.store = 'appointments';",
);

const ruleLoggedUsersExceptForSettings = "@request.auth.id != \"\" && store != \"settings_global\"";
const ruleEitherLoggedOrSettings = "@request.auth.id != \"\" || store = \"settings_global\"";
