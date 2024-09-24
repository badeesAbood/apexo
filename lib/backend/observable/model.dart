import '../utils/uuid.dart';

class Model {
  String id;
  bool? archived;
  String title;
  String? get avatar {
    return null;
  }

  Model.fromJson(Map<String, dynamic> json)
      : id = uuid(),
        title = "" {
    id = json["id"] ?? id;
    archived = json["archived"];
    title = json["title"] ?? title;
  }

  Map<String, String> get labels {
    return {};
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    final d = Model.fromJson({});

    json['id'] = id;
    if (archived != d.archived) json['archived'] = archived;
    if (title != d.title) json["title"] = title;
    return json;
  }
}


/**
 ********* Example usage

class MyClass extends Doc {
  String name = '';
  int age = 0;

  MyClass.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = json["name"] ?? name;
    age = json["age"] ?? age;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = MyClass.fromJson({});
    if (name != d.name) json['name'] = name;
    if (age != d.age) json['age'] = age;
    return json;
  }

  get ageInDays => age * 365;
}
*/