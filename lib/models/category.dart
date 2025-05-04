import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  // Create a Category from a Map (for database operations)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: _getIconFromCode(map['iconCode']),
      color: Color(map['colorValue']),
    );
  }

  // Convert Category to a Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
    };
  }

  // Helper method to get constant IconData from icon code
  static IconData _getIconFromCode(int codePoint) {
    // This approach uses a switch statement with constant IconData objects
    // Add more cases for icons you're using in your app
    switch (codePoint) {
      case 0xe59c:
        return Icons.restaurant;
      case 0xe57f:
        return Icons.home;
      case 0xe55f:
        return Icons.directions_car;
      case 0xe57d:
        return Icons.health_and_safety;
      case 0xe7e3:
        return Icons.shopping_cart;
      case 0xef39:
        return Icons.school;
      case 0xe0c8:
        return Icons.local_movies;
      case 0xe7ee:
        return Icons.sports;
      case 0xef6e:
        return Icons.travel_explore;
      case 0xe540:
        return Icons.celebration;
      case 0xe06d:
        return Icons.credit_card;
      case 0xe5e0:
        return Icons.phone;
      case 0xe335:
        return Icons.wifi;
      case 0xe332:
        return Icons.web;
      // Add default case or more icon mappings as needed
      default:
        return Icons.category; // Default icon as fallback
    }
  }
}
