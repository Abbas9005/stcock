import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({super.key});

  @override
  SalesFormScreenState createState() => SalesFormScreenState();
}

class SalesFormScreenState extends State<SalesFormScreen> {
  final TextEditingController dateAddedController = TextEditingController();
  final TextEditingController customername = TextEditingController();
  final TextEditingController bankname = TextEditingController();
  final TextEditingController contect = TextEditingController();
  final TextEditingController amountpaid = TextEditingController();
  final TextEditingController amountexpanses = TextEditingController();
  final TextEditingController squantite = TextEditingController();
  final TextEditingController uniteprice = TextEditingController();
  TextEditingController invoiceNumberController = TextEditingController();
  TextEditingController kataNumberController = TextEditingController();
   TextEditingController TotalAmount = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, int> _itemQuantities = {};
  Map<String, List<Map<String, dynamic>>> _stockData = {};
  final Map<String, double> itQuantities = {};
  List<String> items = [];
  String? selecteitem;
  String? sitem;
  double unitPriceAmount = 0.0;
  double balanceAmount = 0.0;
  double stockquantity = 0.0;
  double textfiledunitprince = 0.0;

  String countectnumber = '';
  String name = '';
  String? selectedExpense;
  bool isHandSelected = false;
  String errorMessage = '';
  String errorquentity = '';
  String? iteamname = '';
  String? cname = '';
  final List<String> expenseItems = ['Rent', 'Food', 'Utilities', 'Other'];
  final TextEditingController customExpenseController =
      TextEditingController();
  var stockBox = Hive.box('stock');
  String? selectedItem;
  double enterquentity = 0.0;
  String? add = '';
  int currentInvoiceNumber = 0;
  List<Map<String, dynamic>> itemDetailsList = [];
  String totalAmount = '';
  String dateController = '';
  DateTime date = DateTime.now();
  double showquantity=0.0;

  @override
  void initState() {
    super.initState();
    dateController = DateTime.now().toString();
    // Initialize SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      currentInvoiceNumber = prefs.getInt('invoiceNumber') ?? 0;
      fetchStockData();
    });
  }

  void clearItemDetailsList() {
    setState(() {
      itemDetailsList = [];
    });
  }

  void clearItemDetails() {
    setState(() {
      selecteitem = null;
      sitem = null;
      iteamname = null;
      cname = null;
      squantite.clear();
      uniteprice.clear();
    });
  }

  void clearForm() {
    setState(() {
      customername.clear();
      contect.clear();
      amountpaid.clear();
      _itemQuantities.clear();
      selecteitem = null;
      sitem = null;
      selectedExpense = null;
      unitPriceAmount = 0.0;
      balanceAmount = 0.0;
      TotalAmount.clear();
      errorMessage = '';
      errorquentity = '';
      amountexpanses.clear();
      squantite.clear();
      enterquentity = 0.0;
      itQuantities.clear();
      customExpenseController.clear();
      invoiceNumberController.clear();
      uniteprice.clear();
      clearItemDetailsList();
      kataNumberController.clear();
    });
  }

  double calculateTotalAmount() {
    return itemDetailsList.fold(
        0.0, (sum, item) => sum + (item['quantity'] * item['unitPrice']));
  }

  double calculateTotalQuantity() {
    return itemDetailsList.fold(0.0, (sum, item) => sum + item['quantity']);
  }

  double calculateTotalUnitPrice() {
    return itemDetailsList.fold(0.0, (sum, item) => sum + item['unitPrice']);
  }

  ListView buildItemDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: itemDetailsList.length + 1, // Add one for the totals row
      itemBuilder: (context, index) {
        if (index == itemDetailsList.length) {
          totalAmount = calculateTotalAmount().toStringAsFixed(2);
          final totalQuantity = calculateTotalQuantity().toStringAsFixed(2);
          final totalUnitPrice = calculateTotalUnitPrice().toStringAsFixed(2);

          // Totals row
          return ListTile(
            title:
                Text('Totals', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Total Amount: $totalAmount, Total Quantity: $totalQuantity, Total Unit Price: $totalUnitPrice',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                // Neon Green
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(2, 2),
                    blurRadius: 5,
                  ),
                ],
                fontFamily: 'Roboto',
              ),
            ),
          );
        } else {
          final item = itemDetailsList[index];
          return ListTile(
            title: Text(
              item['itemName'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[800], // Professional dark blue
              ),
            ),
            subtitle: Text(
              'Category: ${item['category']}, Quantity: ${item['quantity']}, Unit Price: ${item['unitPrice']}',
              style: TextStyle(
                color: Colors.black, // Subtle grey for subtitle
                fontSize: 13,
              ),
            ),
            tileColor: Colors.grey[50], // Very light grey background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Rounded corners
              side: BorderSide(color: Colors.grey[200]!), // Subtle border
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Icon(
              Icons.inventory_2,
              color: Colors.indigo[400], // Matching icon color
            ),
            // Add hover effect with Material widget
            hoverColor: Colors.indigo[50],
          );
        }
      },
    );
  }

  final List<String> Bank = [
    'Easypaisa',
    'Bank of khyber',
    'Alfala Bank',
    'UBL',
    'HBL',
    'Islamic',
    'Bank of punjab',
    'Mazain',
    'MCB '
  ];
  String? selectedbank;

  void addbanke(BuildContext context) {
    TextEditingController bankcontorler = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          backgroundColor: Colors.blueGrey.shade50, // Light background color
          title: Center(
            child: Text(
              'Add New Bank',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800, // Highlight color for the title
              ),
            ),
          ),
          content: TextFormField(
            controller: bankcontorler,
            maxLength: 23,
            decoration: InputDecoration(
              labelText: 'Bank Name',
              labelStyle: TextStyle(
                color: Colors.teal.shade600, // Label text color
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.teal.shade600), // Focus color
              ),
            ),
            cursorColor: Colors.teal.shade600, // Cursor color
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, // "Cancel" button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade800, // "Add" button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (bankcontorler.text.isNotEmpty) {
                  setState(() {
                    Bank.add(bankcontorler.text);
                    selectedbank = bankcontorler.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String generateCompositeKey(String itemName, String category) {
    return '$itemName-$category'.trim();
  }

  double getQuantityFromStock(String itemName, String category) {
    var item = stockBox.values.firstWhere(
        (element) =>
            element['itemName'] == itemName && element['category'] == category,
        orElse: () => {'quantity': '0'});

    double quantity =
        double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
    double total = double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;
    stockquantity = quantity;
    textfiledunitprince = double.tryParse(uniteprice.text.trim()) ?? 0.0;
    double itemCode =
        double.tryParse(item['itemCode']?.toString() ?? '0') ?? 0.0;
    double unitPrice =
        double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0;
    DateTime date =
        DateFormat('yyyy-MM-dd').tryParse(item['date']?.toString() ?? '') ??
            DateTime.now();
    String formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    double balanceAmount = double.tryParse(squantite.text.trim()) ?? 0.0;
    double buy = balanceAmount * textfiledunitprince;

    setState(() {
      if (balanceAmount > quantity) {
        setState(() {
            showquantity=quantity;
        });
      
        errorquentity = 'null'; // Assign null (if it's expected to hold null)
      } else {
        errorquentity = ''; // Assign an empty string
        quantity = quantity - balanceAmount; // Update quantity

        itemDetailsList.add({
          'itemName': itemName,
          'category': category,
          'quantity': balanceAmount,
          'unitPrice': textfiledunitprince,
          'total': total,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorquentity == 'null'
                ? 'Error: Insufficient quantity'
                : 'Quantity updated successfully'),
            duration: Duration(seconds: 3),
          ),
        );
        var existingKey = stockBox.keys.firstWhere((key) {
          var existingItem = stockBox.get(key);
          return existingItem['itemName'] == itemName &&
              existingItem['category'] == category;
        }, orElse: () => null);
        if (existingKey != null) {
          stockBox.put(existingKey, {
            'itemName': itemName,
            'category': category,
            'quantity': quantity,
            'itemCode': itemCode,
            'unitPrice': unitPrice,
            'dateAdded': formattedDate,
            'total': total,
            'buy': buy,
          });
          debugPrint('$quantity');
        }
        updateBalance();
        clearItemDetails();
      }
    });

    return quantity;
  }

  Future<pw.Image> buildImage() async {
    final image = await flutterImageProvider(
      AssetImage('assets/apex/apex_logo.jpg'),
    );
    return pw.Image(
      image,
      width: 60,
      height: 60,
    );
  }

  Future<pw.Image> gmImage() async {
    final imag = await flutterImageProvider(
      AssetImage('assets/gm/gmsolar.jpg'),
    );
    return pw.Image(
      imag,
      width: 60,
      height: 60,
    );
  }

  void saveprint() {
    if (customername.text == '' || _itemQuantities.isEmpty || cname == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields!")),
      );
      return;
    } else {
      generateReceipt;
    }
  }

  Future<void> fetchStockData() async {
    final stockBox = Hive.box('stock');
    final stockList = stockBox.values.toList();
    setState(() {
      _stockData = {};
      for (var item in stockList) {
        if (item is Map && item.containsKey('itemName')) {
          final itemName = item['itemName'];
          if (!_stockData.containsKey(itemName)) {
            _stockData[itemName] = [];
          }
          _stockData[itemName]!.add({
            'category': item['category'] ?? 'Uncategorized',
            'itemCode': item['itemCode'] ?? 'N/A',
            'unitPrice': item['unitPrice'] ?? 0.0,
            'Quantity': item['quantity'] ?? 0.0,
          });
        }
      }
      items = _stockData.keys.toList();
    });
  }

  void handleAeroSelection(String selectedItem) {
    if (selectedItem == "Aero") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have selected Aero.')),
      );
    }
  }

  void addCustomExpense(String customExpense) {
    setState(() {
      if (!expenseItems.contains(customExpense)) {
        expenseItems.insert(
            expenseItems.length - 1, customExpense); // Add before "Other"
      }
      selectedExpense = customExpense;
    });
  }

  Widget buildText({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  void updateunitPriceAmount() {
    setState(() {
      unitPriceAmount = _itemQuantities.entries.fold(
        0.0,
        (sum, entry) {
          final category = entry.key;
          final unitPrice = _stockData[selectedItem]?.firstWhere(
                  (details) => details['category'] == category,
                  orElse: () => {'unitPrice': 0.0})['unitPrice'] ??
              0.0;
          return sum + (entry.value * unitPrice);
        },
      );
      final amountPaid = double.tryParse(amountpaid.text) ?? 0.0;
      balanceAmount = unitPriceAmount - amountPaid;
      if (balanceAmount < 0) balanceAmount = 0;
    });
  }

  Widget multicatagrory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.0),
        GestureDetector(
          onTap: showMultiSelectItemDialog,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 2.0, // Adjust the width to make the border bold
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _itemQuantities.keys.isEmpty
                        ? 'Select catagory'
                        : _itemQuantities.keys.join(', '),
                    style: TextStyle(
                        fontSize: 16.0, overflow: TextOverflow.ellipsis),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

void updateBalance() {
  final amountPaid = double.tryParse(amountpaid.text) ?? 0.0;
  final totalAmount = calculateTotalAmount();

  setState(() {
    if (amountPaid > totalAmount) {
      errorMessage = "bigto"; // Assuming "bigto" is the error message for this case
      balanceAmount = totalAmount - amountPaid; // Reset balance
    } else {
      errorMessage = "null";
      balanceAmount = totalAmount - amountPaid;
    }
    TotalAmount.text = totalAmount.toStringAsFixed(2);
  });
}


  void showMultiSelectItemDialog() {
    if (selectedItem == null) return;
    bool isCheck = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                'Select Categories',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      Color(0xFF1A73E8), // Google Blue - modern and widely used
                  letterSpacing: -0.5, // Tighter letter spacing for modern look
                ),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _stockData[selectedItem]!
                      .map((categoryDetails) {
                        final categoryName = categoryDetails['category'];
                        return CheckboxListTile(
                          title: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(
                                  0xFF202124), // Material Dark - better readability
                              height: 1.2, // Improved line height
                            ),
                          ),
                          value: _itemQuantities.containsKey(categoryName),
                          onChanged: (bool? isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                _itemQuantities[categoryName] = 1;
                                cname = categoryName;
                              } else {
                                _itemQuantities.remove(categoryName);
                              }
                              updateunitPriceAmount();
                            });
                          },
                          activeColor: Color(0xFF1A73E8), // Google Blue
                          checkColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          tileColor: Colors.transparent,
                          selectedTileColor:
                              Color(0xFFE8F0FE), // Light blue when selected
                        );
                      })
                      .toList()
                      .cast<Widget>(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8), // Google Blue
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              backgroundColor: Colors.white,
              elevation: 8.0, // Reduced elevation for modern look
              insetPadding:
                  EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }

  Widget buildDropdown<T>({
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    T? value,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF1A73E8),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.black,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(0xFF1A73E8),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2,
          ),
        ),
      ),
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: Color(0xFF1A73E8),
        size: 28,
      ),
      dropdownColor: Colors.white,
      style: TextStyle(
        color: Color(0xFF1A73E8),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      onChanged: (T? selectedValue) {
        if (selectedValue != null && selectedValue is String) {
          setState(() {
            selectedItem = selectedValue;
            fetchCategoriesForItem(selectedItem!);
          });
        }
        onChanged(selectedValue);
      },
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    color: Color(0xFF202124),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ))
          .toList(),
      isExpanded: true, // Makes dropdown take full width
      hint: Text(
        'Select an option',
        style: TextStyle(
          color: Color(0xFF757575),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  void fetchCategoriesForItem(String selectedItem) {
    setState(() {
      _itemQuantities.clear();
      final categories = _stockData[selectedItem];
      if (categories != null) {
        for (var category in categories) {
          final categoryName = category['itemName'];
          if (categoryName != null) {
            _itemQuantities[categoryName] = 0;
          }
        }
      }
    });
  }

  Future<void> generateReceipt() async {
    final customer = customername.text;
    final Total =TotalAmount.text;
    final data = dateAddedController.text.trim();
    final contactInfo = contect.text.trim();
    final unitPrice = double.tryParse(uniteprice.text) ?? 0.0;
    final customerNumber = contect.text;
    final pwgmimge = await gmImage();
    final pwImage = await buildImage();
    debugPrint('customer$customer');
    // if (_formKey.currentState?.validate() ?? false) {
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(SnackBar(content: Text('Form is valid!')));
    // }

    if (iteamname != null) {
      getQuantityFromStock(iteamname!, cname!);
    }
    if (errorquentity == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('your are enter invilde quantity')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    currentInvoiceNumber = prefs.getInt('invoiceNumber') ?? 0;

    final invoiceNumber = invoiceNumberController.text.trim();
    if (invoiceNumber.isEmpty) {
      currentInvoiceNumber++;
      prefs.setInt('invoiceNumber', currentInvoiceNumber);

      setState(() {
        invoiceNumberController.text = currentInvoiceNumber.toString();
      });
    } else {
      currentInvoiceNumber = int.parse(invoiceNumber);
      prefs.setInt('invoiceNumber', ++currentInvoiceNumber);
    }

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 50,
                        height: 50,
                        child: pwgmimge,
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('Apex Solar Bannu Branch ',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              'Back side central jail, Link Road, Bannu Township',
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Contact:",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("(0928)633753",
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Container(
                        width: 50,
                        height: 50,
                        child: pwImage,
                      ),
                    ],
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Bill To: $customer',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('InvoiceNO: $currentInvoiceNumber',
                          style: pw.TextStyle(fontSize: 12)),
                      pw.Text('Date: $data', style: pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Row(children: [
                    pw.Text("CustomerNumber: $countectnumber",
                        style: pw.TextStyle(fontSize: 12)),
                  ]),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Text('s.No',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text('  Iteam Name',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text(' Category',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text('Quantity',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text('Unit Price',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text('Amount',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ],
                      ),
                      ...itemDetailsList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final itemName = item['itemName'];
                        final category = item['category'];
                        final quantity = item['quantity'];
                        final unitPrice = item['unitPrice'];
                        final Amount = quantity * unitPrice;

                        return pw.TableRow(
                          children: [
                            pw.Text((index + 1).toString(),
                                style: pw.TextStyle(fontSize: 10)),
                            pw.Text(itemName,
                                style: pw.TextStyle(fontSize: 10)),
                            pw.Text(category,
                                style: pw.TextStyle(fontSize: 10)),
                            pw.Text(quantity.toString(),
                                style: pw.TextStyle(fontSize: 10)),
                            pw.Text(unitPrice.toStringAsFixed(2),
                                style: pw.TextStyle(fontSize: 10)),
                            pw.Text(Amount.toStringAsFixed(2),
                                style: pw.TextStyle(fontSize: 10)),
                          ],
                        );
                      }),
                      // Totals Row
                      pw.TableRow(
                        children: [
                          pw.Text('Totals',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(''),
                          pw.Text(calculateTotalAmount().toStringAsFixed(2),
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    isHandSelected
                        ? 'Payment Method: by Hand'
                        : 'Payment Method: by Bank',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Amount Paid: ${amountpaid.text}',
                          style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Bankname : $selectedbank',
                          style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('Balance Amount: $balanceAmount',
                          style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text("Head office:",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Naseer Abad Stop,",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Opp Kohinoor Mills, Peshawar Road",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Rawalpindi,",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Website: www.gmsolar.com.pk",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Email: gmainoor_afridi@yahoo.com",
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 10, width: 150),
                      pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // pw.Text("              ", style: pw.TextStyle(fontSize: 10)),
                          pw.Text("SIGNATURE:______________",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                          pw.Text("Gudam Bannu Link Road Behind",
                              style: pw.TextStyle(fontSize: 10)),
                          pw.Text("Bannu Jail, KPK",
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

// Assuming _dateAddedController is a TextEditingController
      if (dateAddedController.text.isEmpty) {
        DateTime now = DateTime.now();
        dateAddedController.text = DateFormat('yyyy-MM-dd').format(now);
      }

      final transactionData = {
        'customerName': customer,
        'contactInfo': contactInfo,
        'items': itemDetailsList,
        'amountPaid': amountpaid.text,
        'balanceAmount': balanceAmount,
        'date': dateAddedController.text,
        'AmountExpense': amountexpanses.text,
        'Expense': selectedExpense,
        'byhandbybank': isHandSelected ? 'by Hand' : 'byBank',
        'kataNumberController': kataNumberController.text,
        'InvoiceNO': currentInvoiceNumber.toDouble(),
        'Total': Total,
        'Bankname': selectedbank,
      };
      if (balanceAmount == 0.0) {
        //  await Hive.box('receipts').add(transactionData);
         await Hive.box('receipts').add(transactionData);
        await Hive.box('dailyupdata').add(transactionData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Data saved to Roznamcha  Records successfully!")),
        );
      } else {
        await Hive.box('dailyupdata').add(transactionData);
        await Hive.box('receipts').add(transactionData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Data saved to Kata successfully!")),
        );
      }
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Receipt saved and printed successfully!")),
      );
      clearForm();
    } catch (e) {
      debugPrint("Error during receipt generation/printing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate/print receipt.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
              child: Text(
        'Sales Form',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Roboto',
        ),
      ))),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Colors.white, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          height: 500,
          width: 700,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Colors.white, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 300,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: TextField(
                            controller: dateAddedController,
                            decoration: InputDecoration(
                              labelText: 'Date (yyyy-MM-dd)',
                              labelStyle: TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .transparent, // You can also set the color of the border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .transparent, // You can also set the color of the border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .transparent, // You can also set the color of the border
                                ),
                              ),
                            ),
                            readOnly: true,
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                dateAddedController.text =
                                    DateFormat('yyyy-MM-dd').format(pickedDate);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 50),
                      Text(
                        'Invoicenumber: $currentInvoiceNumber',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: kataNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'kataNumber',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          buildDropdown<String>(
                            label: 'iteam',
                            items: items,
                            value: selecteitem,
                            onChanged: (value) => setState(() {
                              selecteitem = value;
                              sitem = value;
                              iteamname = value;

                              fetchCategoriesForItem(selecteitem!);
                            }),
                          ),
                          SizedBox(height: 10),
                          multicatagrory(),
                          SizedBox(height: 10),
                          TextField(
                            controller: squantite,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                enterquentity =
                                    double.tryParse(squantite.text.trim()) ??
                                        0.0;
                              });
                            },
                          ),
                          if (errorquentity == 'null')
                            if (enterquentity > stockquantity)
                              Text(
                                ' Stock Quantity Equal to  $showquantity',
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                          SizedBox(height: 10),
                          TextField(
                            controller: uniteprice,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'unite price',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                            ),
                            onChanged: (_) => updateBalance(),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              getQuantityFromStock(iteamname!, cname!);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Purchase',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: invoiceNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Invoice Number',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          _buildTextField(
                            controller: customername,
                            labelText: 'Customer Name',
                            //  name=customername.text.toString()
                          ),
                          SizedBox(height: 10),
                          Form(
                            key: formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: contect,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(11),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Number',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width:
                                            2.0, // Adjust the width to make the border bold
                                        color: Colors
                                            .black, // You can also set the color of the border
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width:
                                            2.0, // Adjust the width to make the border bold
                                        color: Colors
                                            .black, // You can also set the color of the border
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width:
                                            2.0, // Adjust the width to make the border bold
                                        color: Colors
                                            .black, // You can also set the color of the border
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    countectnumber = value.toString();

                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a customer number';
                                    } else if (value.length < 11) {
                                      return 'Customer number must be 11 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: isHandSelected,
                                onChanged: (value) {
                                  setState(() {
                                    isHandSelected = value!;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                              Text(
                                'by Cash',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isHandSelected
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              Radio<bool>(
                                value: false,
                                groupValue: isHandSelected,
                                onChanged: (value) {
                                  setState(() {
                                    isHandSelected = value!;
                                    amountpaid.clear();
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                              Text(
                                'by Bank',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: !isHandSelected
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          isHandSelected
                              ? TextField(
                                  controller: amountpaid,
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Amount Paid',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width:
                                            2.0, // Adjust the width to make the border bold
                                        color: Colors
                                            .black, // You can also set the color of the border
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width:
                                            2.0, // Adjust the width to make the border bold
                                        color: Colors
                                            .black, // You can also set the color of the border
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        width:
                                            2.0, // Adjust the width to make the border bold
                                        color: Colors
                                            .black, // You can also set the color of the border
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => updateBalance(),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 50,
                                            width: 250,
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: selectedbank,
                                              decoration: InputDecoration(
                                                labelText: 'Select Bank Name',
                                                labelStyle: TextStyle(
                                                  color: Colors.teal.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                fillColor: Colors.transparent,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.teal.shade700),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color:
                                                          Colors.teal.shade900),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              items: Bank.map((category) {
                                                return DropdownMenuItem(
                                                  value: category,
                                                  child: Text(
                                                    category,
                                                    style: TextStyle(
                                                        color: Colors
                                                            .teal.shade900),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedbank = value;
                                                });
                                              },
                                              validator: (value) => value ==
                                                      null
                                                  ? 'Please select a category'
                                                  : null,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add,
                                              size: 30,
                                            ),
                                            color: Colors.teal.shade800,
                                            onPressed: () => addbanke(context),
                                            tooltip: 'Add New bank',
                                          ),
                                        ],
                                      ),
                                      TextField(
                                        controller: amountpaid,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: 'Amount Paid',
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              width:
                                                  2.0, // Adjust the width to make the border bold
                                              color: Colors.teal
                                                  .shade800, // You can also set the color of the border
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              width:
                                                  2.0, // Adjust the width to make the border bold
                                              color: Colors.teal
                                                  .shade800, // You can also set the color of the border
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              width:
                                                  2.0, // Adjust the width to make the border bold
                                              color: Colors
                                                  .black, // You can also set the color of the border
                                            ),
                                          ),
                                        ),
                                        onChanged: (_) => updateBalance(),
                                      )
                                    ],
                                  ),
                                ),
                        TextFormField(
                            controller: TotalAmount,
                            
                            keyboardType: TextInputType.number,
                            
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            
                            decoration: InputDecoration(
                              labelText: 'Total',
                                labelStyle:  TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .black, // You can also set the color of the border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .transparent, // You can also set the color of the border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width:
                                      2.0, // Adjust the width to make the border bold
                                  color: Colors
                                      .transparent, // You can also set the color of the border
                                ),
                              ),
                            ),
                            validator: (value) {
                              return null;
                            },
                          ),
                         
                          if (errorMessage == "bigto")
                            Text(
                              'you Amount paind is greater than Balance',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          if (errorMessage == "null")
                            Text(
                              'Balance: ${balanceAmount % 1 == 0 ? balanceAmount.toInt().toString() : balanceAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          SizedBox(height: 20),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: const [Colors.blue, Colors.green],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: clearForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      'Clear',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: const [
                                        Colors.purple,
                                        Colors.orange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: generateReceipt,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: Text(
                                      'Save & Print',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                    height: 180, width: 500, child: buildItemDetailsList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            width: 2.0, // Adjust the width to make the border bold
            color: Colors.black, // You can also set the color of the border
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 2.0, // Adjust the width to make the border bold
            color: Colors.black, // You can also set the color of the border
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 2.0, // Adjust the width to make the border bold
            color: Colors.black, // You can also set the color of the border
          ),
        ),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}
