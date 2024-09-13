import '../../../backend/observable/model.dart';

class Component extends Model {
  String name = '';
  int quantity = 0;
  String unit = '';
  Component.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = json["name"] ?? name;
    quantity = json["quantity"] ?? quantity;
    unit = json["unit"] ?? unit;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Component.fromJson({});
    if (name != d.name) json['name'] = name;
    if (quantity != d.quantity) json['quantity'] = quantity;
    if (unit != d.unit) json['unit'] = unit;
    return json;
  }
}

class Recipe extends Model {
  int estimatedPrice = 0;
  String details = '';
  List<Component> components = [];

  @override
  Map<String, String> get labels {
    return {"price": estimatedPrice.toString(), "components number": components.length.toString()};
  }

  Recipe.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    estimatedPrice = json["estimatedPrice"] ?? estimatedPrice;
    details = json["details"] ?? details;
    if (json["components"] != null) {
      components = [];
      for (var component in json["components"]) {
        components.add(Component.fromJson(component));
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Recipe.fromJson({});
    if (estimatedPrice != d.estimatedPrice) json['estimatedPrice'] = estimatedPrice;
    if (details != d.details) json['details'] = details;
    if (components.isNotEmpty) {
      json['components'] = [];
      for (var component in components) {
        json['components'].add(component.toJson());
      }
    }
    return json;
  }
}
