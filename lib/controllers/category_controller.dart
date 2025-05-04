import 'package:get/get.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryController extends GetxController {
  final DatabaseService _db = Get.find<DatabaseService>();

  final RxList<Category> categories = <Category>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      categories.value = await _db.getCategories();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(Category category) async {
    isLoading.value = true;
    try {
      await _db.insertCategory(category);
      categories.add(category);
      Get.back(); // Navigate back after adding
      Get.snackbar('Success', 'Category added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add category: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCategory(Category category) async {
    isLoading.value = true;
    try {
      await _db.updateCategory(category);
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = category;
      }
      Get.back(); // Navigate back after editing
      Get.snackbar('Success', 'Category updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update category: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(String id) async {
    isLoading.value = true;
    try {
      await _db.deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      Get.snackbar('Success', 'Category deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Category? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
