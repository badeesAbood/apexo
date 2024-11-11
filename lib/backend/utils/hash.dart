import 'package:apexo/backend/utils/constants.dart';

String simpleHash(String input) {
  int hash = 0;

  // Generate a basic hash using the characters of the input string.
  for (int i = 0; i < input.length; i++) {
    hash = (hash * 31 + input.codeUnitAt(i)) & 0xFFFFFFFF; // Basic hash function with bitwise AND
  }

  // Convert the hash to a string of Latin alphabet characters.
  StringBuffer result = StringBuffer();
  while (hash != 0) {
    int index = hash % alphabet.length;
    result.write(alphabet[index]);
    hash = hash ~/ alphabet.length;
  }

  return "h${result.toString().isEmpty ? alphabet[0] : result.toString()}";
}
