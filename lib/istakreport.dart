import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class istakfordescrption extends StatefulWidget {
  final String itemName;
  final double total;
  final String dateAdded;

  istakfordescrption({
    required this.itemName,
    required this.total,
    required this.dateAdded,
  });

  @override
  _istakfordescrptionState createState() => _istakfordescrptionState();
}

class _istakfordescrptionState extends State<istakfordescrption> {
  final TextEditingController _searchController = TextEditingController();
  late Box<dynamic> _dailyupdataBox;
  List<Map<dynamic, dynamic>> _allRecords = [];
  List<Map<dynamic, dynamic>> _filteredRecords = [];
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  double totalsell = 0.0;
  double Remainingquantity = 0.0;

  @override
  void initState() {
    super.initState();
    Remainingquantity = widget.total;
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _dailyupdataBox = await Hive.openBox('dailyupdata');
    _loadRecords();
  }

  void _loadRecords() {
    List<Map<dynamic, dynamic>> records = [];

    _dailyupdataBox.values.forEach((record) {
      if (record is Map && record['items'] is List) {
        List items = record['items'] as List;
        items.forEach((item) {
          if (item['itemName'] == widget.itemName) {
            records.add({
              ...record,
              'matchedItem': item,
            });
          }
        });
      }
    });

    setState(() {
      _allRecords = records;
      _filteredRecords = List.from(records.reversed);
      _calculateTotalSell();
    });
  }

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = List.from(_allRecords.reversed);
      } else {
        _filteredRecords = _allRecords.where((record) {
          final customerName = record['customerName']?.toString().toLowerCase() ?? '';
          final date = record['date']?.toString() ?? '';

          bool isDateQuery = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(query);

          if (isDateQuery) {
            return date.contains(query);
          } else {
            return customerName.contains(query.toLowerCase());
          }
        }).toList().reversed.toList();
      }
      _calculateTotalSell();
    });
  }

  void _calculateTotalSell() {
    double totalSell = 0.0;
    for (var record in _filteredRecords) {
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by Customer Name',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                  ),
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
                onChanged: _filterRecords,
              ),
            ),
            SizedBox(width: 12,),
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
            _filteredRecords.isEmpty
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
              : Container(
                height: 500,
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      ScrollbarTheme(
                        data: ScrollbarThemeData(
                          thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.black;
                            }
                            return Colors.grey.shade500;
                          }),
                          trackColor: MaterialStateProperty.all(Colors.transparent),
                          trackVisibility: MaterialStateProperty.all(true),
                          thickness: MaterialStateProperty.all(10.0),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _horizontalScrollController,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horizontalScrollController,
                            child: Scrollbar(
                              thumbVisibility: true,
                              controller: _verticalScrollController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                controller: _verticalScrollController,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Totalstock')),
                                    DataColumn(label: Text('Remaining stock ')),
                                    DataColumn(label: Text('Quantity')),
                                    DataColumn(label: Text('Unit Price')),
                                    DataColumn(label: Text('Total')),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Invoice No')),
                                    DataColumn(label: Text('Customer Name')),
                                  ],
                                  rows: [
                                    // First row with widget values
                                    DataRow(
                                      cells: [
                                        DataCell(Text(widget.total.toString())),
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
                                    ..._filteredRecords.reversed.map((record) {
                                      final item = record['matchedItem'];
                                      final quantity = item['quantity'];

                                      Remainingquantity = Remainingquantity - quantity;

                                      final totalof = item['quantity'] * item['unitPrice'];

                                      return DataRow(
                                        cells: [
                                          DataCell(Text('')),
                                          DataCell(Text('$Remainingquantity')),
                                          DataCell(Text(item['quantity']?.toString() ?? '')),
                                          DataCell(Text(item['unitPrice']?.toString() ?? '')),
                                          DataCell(Text('$totalof')),
                                          DataCell(Text(_formatDate(record['date']?.toString() ?? ''))),
                                          DataCell(Text(record['InvoiceNO']?.toString() ?? '')),
                                          DataCell(Text(record['customerName']?.toString() ?? '')),
                                        ],
                                      );
                                    }).toList(),
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

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
