import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeProvider with ChangeNotifier {
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> searchRecipes(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          _recipes = (data['meals'] as List).map((meal) => Recipe.fromJson(meal)).toList();
        } else {
          _recipes = [];
        }
      } else {
        _error = 'Failed to load recipes. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load some default recipes
  Future<void> loadRandomRecipes() async {
    // For simplicity, we just search for a generic letter or common word
    await searchRecipes('chicken');
  }
}
