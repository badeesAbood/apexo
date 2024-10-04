import 'dart:convert';

void main() {
  final Map<String, int> map = {"a": 1, "b": 2};
  final json = jsonEncode(map);
  final Map<String, int> decoded = Map<String, int>.from(jsonDecode(json));
  print(json);
  print(map.runtimeType);
  print(decoded.runtimeType);
  print(decoded["a"]);
}
