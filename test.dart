void main() {
  var a = [1, 2, 3, 4, 5];
  print(a..sort((a, b) => b.compareTo(a)));
}
