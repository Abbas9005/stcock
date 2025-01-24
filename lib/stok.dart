import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_stock/databas.dart';
import 'package:my_stock/stockreport.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  _StockManagementScreenState createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _dateAddedController = TextEditingController();

  // Hive Database Helper
  final HiveDatabaseHelper _hiveDbHelper = HiveDatabaseHelper();

  // Category management
  final List<String> _categories = [
    'Apex lithium battery 51v100A',
    'Apex solar inverter on grid',
    'Apex solar inverter ip21',
    'Apex solar inverter hybrid ip65'
  ];
  String? _selectedCategory;

  void TotalStock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockReport()),
    );
  }

  void _addCategory(BuildContext context) {
    TextEditingController categoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextFormField(
            controller: categoryController,
            decoration: const InputDecoration(labelText: 'Category Name'),
              inputFormatters: [
    LengthLimitingTextInputFormatter(27), // Limit input to 20 characters
  ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (categoryController.text.isNotEmpty) {
                  setState(() {
                    _categories.add(categoryController.text);
                    _selectedCategory = categoryController.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveStock(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog before saving
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFF4F6F8), // Soft light background
            title: const Text(
              'Confirm Save',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B), // Dark neutral tone
              ),
            ),
            content: const Text(
              'Are you sure you want to save this stock item?',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF475569), // Muted gray-blue
              ),
            ),
            actions: <Widget>[
              // Cancel Button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: const Color(0xFFEF4444), // Vibrant red
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              // Confirm Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Map<String, dynamic> item = {
                    'itemName': _itemNameController.text,
                    'category': _selectedCategory,
                    'quantity': int.tryParse(_quantityController.text) ?? 0,
                    'itemCode': _itemCodeController.text,
                    'unitPrice': double.tryParse(_unitPriceController.text) ?? 0.0,
                    'dateAdded': _dateAddedController.text,
                    'total': double.tryParse(_quantityController.text) ?? 0.0,

                  };

                  _hiveDbHelper.saveItem(item).then((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock item saved successfully!'),
                          backgroundColor: Color(0xFF4CAF50), // Green
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    _resetForm();
                  }).catchError((e) {
                    debugPrint("Error saving stock item: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save stock item.'),
                          backgroundColor: Color(0xFFEF4444), // Red
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFF3B82F6), // Modern blue
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget Textitem(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue.shade900),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade900),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: inputType,
      validator: (value) {
        if (value!.isEmpty) {
          return '$label is required';
        }
        // Additional validation for number fields
        if (inputType == TextInputType.number) {
          if (inputType == TextInputType.number &&
              double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Only digits
        LengthLimitingTextInputFormatter(8),  // Limit input to 8 characters
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue.shade900),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade900),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: inputType,
      validator: (value) {
        if (value!.isEmpty) {
          return '$label is required';
        }
        // Additional validation for number fields
        if (inputType == TextInputType.number) {
          if (inputType == TextInputType.number &&
              double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  void _resetForm() {
    // _itemNameController.clear();
    // _itemCodeController.clear();
    // _quantityController.clear();
    // _unitPriceController.clear();
    // _dateAddedController.clear();
    setState(() {
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stock Management',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Container(
          // Ensure the container covers the entire screen
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.blue.shade100], // Gradient color (white to light blue)
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: SizedBox(
                              width: 200,
                              child: Textitem('Item Name', _itemNameController),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              
                              child: _buildCategoryDropdown(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: SizedBox(
                              width: 300,
                              child: _buildTextField(
                                'Item Code',
                                _itemCodeController,
                                inputType: TextInputType.number,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: SizedBox(
                              width: 200,
                              child: _buildTextField(
                                'Quantity',
                                _quantityController,
                                inputType: TextInputType.number,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: SizedBox(
                              width: 300,
                              child: _buildTextField(
                                'Unit Price',
                                _unitPriceController,
                                inputType: TextInputType.number,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: SizedBox(
                              width: 200,
                              child: _buildDateField(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildButtonRow(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: TextStyle(color: Colors.blue.shade900),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade900),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
              ),
              // filled: true,
              fillColor: Colors.white,
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.blue),
          onPressed: () => _addCategory(context),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextFormField(
      controller: _dateAddedController,
      decoration: InputDecoration(
        labelText: 'Date Added',
        labelStyle: TextStyle(color: Colors.blue.shade900),
        hintText: 'YYYY-MM-DD',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade900),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? 'Date added is required' : null,
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          _dateAddedController.text =
              pickedDate.toLocal().toString().split(' ')[0];
        }
      },
    );
  }

  Widget _buildButtonRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        bottonshow(
          'Save',
          [Colors.blue.shade900, Colors.blue.shade700], // Example gradient colors
          () => _saveStock(context),
        ),
        const SizedBox(width: 10),
        bottonshow(
          'Clear',
          [Colors.pink.shade400, Colors.orange.shade400], // Example gradient colors
          _resetForm,
        ),
        const SizedBox(width: 10),
        bottonshow(
          'Total Stock',
          [Colors.pink.shade400, Colors.black], // Example gradient colors
          TotalStock,
        ),
      ],
    );
  }

  Widget bottonshow(
      String label, List<Color> gradientColors, Function() onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.6),
            blurRadius: 8,
            offset: Offset(2, 4), // Shadow position
          ),
        ],
        borderRadius: BorderRadius.circular(16), // Slightly more rounded corners
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18, // Slightly larger text
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2, // Added slight letter spacing
          ),
        ),
      ),
    );
  }
}
