import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:my_stock/pdf/reportistock.dart';

class istakfordescrption extends StatefulWidget {
  final String itemName;
  final double total;
  final String dateAdded;

  const istakfordescrption({
    super.key,
    required this.itemName,
    required this.total,
    required this.dateAdded,
  });

  @override
  _istakfordescrptionState createState() => _istakfordescrptionState();
}

class _istakfordescrptionState extends State<istakfordescrption> {
  final TextEditingController searchController = TextEditingController();
  late Box<dynamic> dailyupdataBox;
  List<Map<dynamic, dynamic>> allRecords = [];
  List<Map<dynamic, dynamic>> filteredRecords = [];
  final ScrollController horizontalScrollController = ScrollController();
  final ScrollController verticalScrollController = ScrollController();
  double totalsell = 0.0;
  double Remainingquantity = 0.0;

  @override
  void initState() {
    super.initState();
    Remainingquantity = widget.total;
    initializeBox();
  }

  Future<void> initializeBox() async {
    try {
      dailyupdataBox = await Hive.openBox('dailyupdata');
      loadRecords();
    } catch (e) {
      print('Error initializing Hive box: $e');
    }
  }

  void loadRecords() {
    try {
      List<Map<dynamic, dynamic>> records = [];

      for (var record in dailyupdataBox.values) {
        if (record is Map && record['items'] is List) {
          List items = record['items'] as List;
          for (var item in items) {
            if (item['itemName'] == widget.itemName) {
              records.add({
                ...record,
                'matchedItem': item,
              });
            }
          }
        }
      }

      print('Loaded records: $records'); // Debug print

      setState(() {
        allRecords = records;
        filteredRecords = List.from(records.reversed);
        calculateTotalSell();
      });
    } catch (e) {
      print('Error loading records: $e');
    }
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  void filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecords = List.from(allRecords.reversed);
      } else {
        filteredRecords = allRecords
            .where((record) {
              final customerName =
                  record['customerName']?.toString().toLowerCase() ?? '';
              final date = record['date']?.toString() ?? '';

              bool isDateQuery = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(query);

              if (isDateQuery) {
                return date.contains(query);
              } else {
                return customerName.contains(query.toLowerCase());
              }
            })
            .toList()
            .reversed
            .toList();
      }
      calculateTotalSell();
    });
  }

  void calculateTotalSell() {
    double totalSell = 0.0;
    for (var record in filteredRecords) {
      final item = record['matchedItem'];
      final quantity = item['quantity'];
      final unitPrice = item['unitPrice'];
      final totalof = quantity * unitPrice;
      totalSell += totalof;
    }
    setState(() {
      totalsell = totalSell;
    });
  }

 void _showEditDialog(Map<dynamic, dynamic> record, Map<dynamic, dynamic> item) {
  final TextEditingController quantityController =
      TextEditingController(text: item['quantity']?.toString() ?? '');
  final TextEditingController unitPriceController =
      TextEditingController(text: item['unitPrice']?.toString() ?? '');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Quantity and Unit Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: unitPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Unit Price'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newQuantity = double.tryParse(quantityController.text) ?? 0.0;
                final newUnitPrice = double.tryParse(unitPriceController.text) ?? 0.0;

                // Find the original record in the box
                int recordIndex = -1;
                Map<dynamic, dynamic>? originalRecord;
                
                for (int i = 0; i < dailyupdataBox.length; i++) {
                  var boxRecord = dailyupdataBox.getAt(i);
                  if (boxRecord['date'] == record['date'] && 
                      boxRecord['InvoiceNO'] == record['InvoiceNO']) {
                    recordIndex = i;
                    originalRecord = Map<dynamic, dynamic>.from(boxRecord);
                    break;
                  }
                }

                if (recordIndex != -1 && originalRecord != null) {
                  // Update the specific item in the items list
                  List<dynamic> items = List.from(originalRecord['items']);
                  for (int i = 0; i < items.length; i++) {
                    if (items[i]['itemName'] == widget.itemName) {
                      items[i] = {
                        ...items[i],
                        'quantity': newQuantity,
                        'unitPrice': newUnitPrice,
                      };
                      break;
                    }
                  }
                  
                  // Create updated record
                  Map<dynamic, dynamic> updatedRecord = {
                    ...originalRecord,
                    'items': items,
                  };

                  // Save to Hive
                  await dailyupdataBox.putAt(recordIndex, updatedRecord);
                  
                  // Refresh the UI
                  loadRecords();
                }

                Navigator.of(context).pop();
              } catch (e) {
                print('Error updating record: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating record: $e')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Stock Register :- ${widget.itemName}",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Reportistock(
              itemName: widget.itemName,
              total: widget.total,
              dateAdded: widget.dateAdded)
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Colors.white, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Customer Name',
                  labelStyle: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: filterRecords,
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Total sell: $totalsell',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            filteredRecords.isEmpty
                ? Center(
                    child: Text(
                      'No matching records found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 500,
                    width: 600,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          ScrollbarTheme(
                            data: ScrollbarThemeData(
                              thumbColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                      (Set<WidgetState> states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.black;
                                }
                                return Colors.grey.shade500;
                              }),
                              trackColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              trackVisibility: WidgetStateProperty.all(true),
                              thickness: WidgetStateProperty.all(10.0),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: horizontalScrollController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: horizontalScrollController,
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  controller: verticalScrollController,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    controller: verticalScrollController,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(
                                            label: Text(
                                          'Totalstock',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Remaining stock ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Quantity',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Unit Price',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Total',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Invoice No',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                        DataColumn(
                                            label: Text(
                                          'Customer Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )),
                                      ],
                                      rows: [
                                        // First row with widget values
                                        DataRow(
                                          cells: [
                                            DataCell(
                                                Text(widget.total.toString())),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                            DataCell(Text(widget.dateAdded)),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                          ],
                                        ),
                                        // Remaining rows from filtered records
                                        ...filteredRecords.reversed
                                            .map((record) {
                                          final item = record['matchedItem'];
                                          final quantity = item['quantity'];
                                            final Remaining = item['Remaining'];
                                          Remainingquantity =
                                              Remainingquantity - quantity;

                                          final totalof = item['quantity'] *
                                              item['unitPrice'];

                                          return DataRow(
                                            cells: [
                                              DataCell(Text('')),
                                              DataCell(
                                                  Text('$Remainingquantity')),
                                              DataCell(
                                                GestureDetector(
                                                  onTap: () => _showEditDialog(
                                                      record, item),
                                                  child: Text(item['quantity']
                                                          ?.toString() ??
                                                      ''),
                                                ),
                                              ),
                                              DataCell(Text(item['unitPrice']
                                                      ?.toString() ??
                                                  '')),
                                              DataCell(Text('$totalof')),
                                              DataCell(Text(formatDate(
                                                  record['date']?.toString() ??
                                                      ''))),
                                              DataCell(Text(record['InvoiceNO']
                                                      ?.toString() ??
                                                  '')),
                                              DataCell(Text(
                                                  record['customerName']
                                                          ?.toString() ??
                                                      '')),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
