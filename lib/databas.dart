import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HiveDatabaseHelper {
  final Box _box = Hive.box('stock'); // Access the 'stock' Hive box

  // Save an item
  Future<void> saveItem(Map<String, dynamic> item) async {
    try {
      await _box.add(item);
      debugPrint("Item Saved: $item");
    } catch (e) {
      debugPrint("Error saving item: $e");
    }
  }

  // Fetch all items
  List<Map<String, dynamic>> getAllItems() {
    try {
      return _box.values.toList().cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("Error fetching items: $e");
      return [];
    }
  }

  // Clear all items
  Future<void> clearItems() async {
    await _box.clear();
    debugPrint("All items cleared!");
  }
}
