import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_controller.dart';
import '../models/category.dart';
import 'dart:math';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryController categoryController =
        Get.find<CategoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Obx(() {
        if (categoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoryController.categories.isEmpty) {
          return const Center(
            child: Text('No categories found. Add your first one!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categoryController.categories.length,
          itemBuilder: (context, index) {
            final category = categoryController.categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, color: category.color),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () => _showCategoryDialog(
                          context, categoryController, category),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () =>
                          _confirmDelete(context, categoryController, category),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, categoryController),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(
      BuildContext context, CategoryController categoryController,
      [Category? existingCategory]) {
    // Set a specific width constraint for the dialog
    final dialogWidth = MediaQuery.of(context).size.width * 0.9 < 400
        ? MediaQuery.of(context).size.width * 0.9
        : 400.0;

    Get.dialog(
      Dialog(
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxWidth: dialogWidth),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CategoryDialogContent(
                context: context,
                categoryController: categoryController,
                existingCategory: existingCategory,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CategoryController categoryController,
    Category category,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              categoryController.deleteCategory(category.id);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class CategoryDialogContent extends StatefulWidget {
  final BuildContext context;
  final CategoryController categoryController;
  final Category? existingCategory;

  const CategoryDialogContent({
    super.key,
    required this.context,
    required this.categoryController,
    this.existingCategory,
  });

  @override
  State<CategoryDialogContent> createState() => _CategoryDialogContentState();
}

class _CategoryDialogContentState extends State<CategoryDialogContent> {
  late TextEditingController nameController;
  late Color selectedColor;
  late IconData selectedIcon;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    selectedColor = widget.existingCategory?.color ?? _getRandomColor();
    selectedIcon = widget.existingCategory?.icon ?? Icons.category;

    if (widget.existingCategory != null) {
      nameController.text = widget.existingCategory!.name;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.existingCategory == null ? 'Add Category' : 'Edit Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Select Color',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _getColorOptions().map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: color.value == selectedColor.value
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Select Icon',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _getIconOptions().map((icon) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIcon = icon;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: icon.codePoint == selectedIcon.codePoint
                        ? Border.all(color: selectedColor, width: 2)
                        : null,
                  ),
                  child: Icon(icon, color: selectedColor),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  if (widget.existingCategory == null) {
                    // Add new category
                    final newCategory = Category(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                    );
                    widget.categoryController.addCategory(newCategory);
                  } else {
                    // Update existing category
                    final updatedCategory = Category(
                      id: widget.existingCategory!.id,
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                    );
                    widget.categoryController.updateCategory(updatedCategory);
                  }
                  Get.back();
                } else {
                  Get.snackbar(
                    'Error',
                    'Category name cannot be empty',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: Text(widget.existingCategory == null ? 'ADD' : 'UPDATE'),
            ),
          ],
        ),
      ],
    );
  }

  List<Color> _getColorOptions() {
    return [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
  }

  List<IconData> _getIconOptions() {
    return [
      Icons.home,
      Icons.restaurant,
      Icons.shopping_cart,
      Icons.directions_car,
      Icons.local_gas_station,
      Icons.local_grocery_store,
      Icons.local_hospital,
      Icons.school,
      Icons.local_movies,
      Icons.flight,
      Icons.hotel,
      Icons.fitness_center,
      Icons.sports,
      Icons.local_bar,
      Icons.laptop,
      Icons.smartphone,
      Icons.pets,
      Icons.child_care,
      Icons.savings,
      Icons.attach_money,
      Icons.celebration,
      Icons.card_giftcard,
    ];
  }

  Color _getRandomColor() {
    final random = Random();
    final colors = _getColorOptions();
    return colors[random.nextInt(colors.length)];
  }
}
