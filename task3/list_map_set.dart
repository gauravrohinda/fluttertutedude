void main() {
  List<String> fruits = ["Apple", "Banana", "Mango"];
  fruits.add("Orange");

  print("List:");
  print(fruits);

  Set<int> numbers = {1, 2, 3, 3, 4};
  print("\nSet:");
  print(numbers);

  Map<String, int> marks = {
    "Math": 90,
    "Science": 95,
    "English": 88,
  };

  print("\nMap:");
  marks.forEach((key, value) {
    print("$key : $value");
  });
}