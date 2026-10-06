class Recipe {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String imageUrl;
  final List<String> ingredients;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.imageUrl,
    required this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String> parsedIngredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        parsedIngredients.add('${measure?.toString().trim() ?? ''} ${ingredient.toString().trim()}');
      }
    }

    return Recipe(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'Unknown',
      category: json['strCategory'] ?? 'Unknown',
      area: json['strArea'] ?? 'Unknown',
      instructions: json['strInstructions'] ?? 'No instructions provided.',
      imageUrl: json['strMealThumb'] ?? '',
      ingredients: parsedIngredients,
    );
  }
}
