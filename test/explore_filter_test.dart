// Unit test untuk logika filter pada Explore feature (US-10: Search & Filter).
//
// Fungsi yang diuji: `ExploreState.filteredRecipes`
// Ini adalah computed getter yang menyaring daftar resep berdasarkan
// (1) kategori yang dipilih dan (2) kata kunci pencarian.
//
// Logika ini dipilih karena murni (pure) — tidak bergantung pada Firebase,
// jaringan, atau UI — sehingga ideal untuk diuji secara terisolasi.
//
// Setiap test mengikuti pola Arrange - Act - Assert.

import 'package:flutter_test/flutter_test.dart';
import 'package:quickmenu/data/models/recipe_model.dart';
import 'package:quickmenu/presentation/viewmodels/explore_viewmodel.dart';

void main() {
  // Helper untuk membuat RecipeModel dummy seringkas mungkin.
  RecipeModel makeRecipe({
    required String id,
    required String title,
    List<String> categories = const [],
  }) {
    return RecipeModel(
      id: id,
      title: title,
      duration: '10',
      categories: categories,
      ingredients: '',
      steps: '',
      createdAt: 0,
    );
  }

  // Data resep yang dipakai bersama di sebagian besar test case.
  late List<RecipeModel> sampleRecipes;

  setUp(() {
    sampleRecipes = [
      makeRecipe(id: '1', title: 'Nasi Goreng', categories: ['Makan Malam']),
      makeRecipe(id: '2', title: 'Smoothie Bowl', categories: ['Sarapan', 'Sehat']),
      makeRecipe(id: '3', title: 'Ayam Bakar', categories: ['Makan Malam']),
    ];
  });

  group('ExploreState.filteredRecipes', () {
    test('mengembalikan semua resep ketika tidak ada filter aktif', () {
      // Arrange — state default: kategori "Semua", query kosong.
      final state = ExploreState(allRecipes: sampleRecipes);

      // Act
      final result = state.filteredRecipes;

      // Assert
      expect(result.length, 3);
      expect(result, sampleRecipes);
    });

    test('menyaring resep berdasarkan kategori yang dipilih', () {
      // Arrange
      final state = ExploreState(
        allRecipes: sampleRecipes,
        selectedCategory: 'Makan Malam',
      );

      // Act
      final result = state.filteredRecipes;

      // Assert — hanya resep dengan kategori "Makan Malam".
      expect(result.length, 2);
      expect(result.map((r) => r.id), containsAll(['1', '3']));
    });

    test('filter kategori bersifat case-insensitive', () {
      // Arrange — kategori ditulis dengan huruf kecil semua.
      final state = ExploreState(
        allRecipes: sampleRecipes,
        selectedCategory: 'makan malam',
      );

      // Act
      final result = state.filteredRecipes;

      // Assert
      expect(result.length, 2);
    });

    test('menyaring resep berdasarkan kata kunci pada judul', () {
      // Arrange
      final state = ExploreState(
        allRecipes: sampleRecipes,
        searchQuery: 'ayam',
      );

      // Act
      final result = state.filteredRecipes;

      // Assert
      expect(result.length, 1);
      expect(result.first.title, 'Ayam Bakar');
    });

    test('pencarian juga cocok dengan nama kategori', () {
      // Arrange — "sehat" tidak ada di judul, hanya di kategori resep #2.
      final state = ExploreState(
        allRecipes: sampleRecipes,
        searchQuery: 'sehat',
      );

      // Act
      final result = state.filteredRecipes;

      // Assert
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('menggabungkan filter kategori dan kata kunci secara bersamaan', () {
      // Arrange — kategori "Makan Malam" + cari "nasi" => hanya Nasi Goreng.
      final state = ExploreState(
        allRecipes: sampleRecipes,
        selectedCategory: 'Makan Malam',
        searchQuery: 'nasi',
      );

      // Act
      final result = state.filteredRecipes;

      // Assert
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('mengembalikan list kosong ketika tidak ada resep yang cocok', () {
      // Arrange
      final state = ExploreState(
        allRecipes: sampleRecipes,
        searchQuery: 'pizza',
      );

      // Act
      final result = state.filteredRecipes;

      // Assert
      expect(result, isEmpty);
      expect(state.isEmpty, isTrue);
    });
  });
}
