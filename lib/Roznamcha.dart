import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:my_stock/Expances.dart';
import 'package:my_stock/pdf/pdfroznamcha.dart';


class RoznamchaRecordsScreen extends StatefulWidget {
  const RoznamchaRecordsScreen({super.key});

  @override
  _RoznamchaRecordsScreenState createState() => _RoznamchaRecordsScreenState();
}

class _RoznamchaRecordsScreenState extends State<RoznamchaRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Box<dynamic> _dailyupdataBox;
  List<Map<dynamic, dynamic>> _allRecords = [];
  List<Map<dynamic, dynamic>> _filteredRecords = [];
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  String formattedTotalExpenses = '';
  double totalByHand = 0.0;
  double totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    formattedTotalExpenses='';
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _dailyupdataBox = await Hive.openBox('dailyupdata');
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      totalExpenses = 0.0;
      _allRecords = _dailyupdataBox.values.cast<Map>().toList();
      _filteredRecords = List.from(_allRecords.reversed);
    });
  }

  void _deleteRecord(Map<dynamic, dynamic> record) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.red.shade50,
          title: Center(
            child: Text(
              'Confirm Delete',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.red.shade800,
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                final key = _dailyupdataBox.keys.firstWhere(
                  (k) => _dailyupdataBox.get(k) == record,
                  orElse: () => null,
                );

                if (key != null) {
                  await _dailyupdataBox.delete(key);
                  _loadRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Record deleted successfully',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete record',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
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

  void editExpense(Map<dynamic, dynamic> record) async {
    final TextEditingController expenseController = TextEditingController();
    expenseController.text = record['AmountExpense']?.toString() ?? '';
    final TextEditingController expenseForController = TextEditingController();
    expenseForController.text = record['Expense_for']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.blue.shade50,
          title: Center(
            child: Text(
              'Edit Expense',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: expenseForController,
                decoration: InputDecoration(
                  labelText: 'Expense_For',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(Icons.description, color: Colors.black),
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
                style: TextStyle(color: Colors.black),
                cursorColor: Colors.black,
              ),
              SizedBox(height: 16),
              TextField(
                controller: expenseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Expense Amount',
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: Colors.black),
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
                style: TextStyle(color: Colors.black),
                cursorColor: Colors.black,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                Navigator.of(context).pop();

                final key = _dailyupdataBox.keys.firstWhere(
                  (k) => _dailyupdataBox.get(k) == record,
                  orElse: () => null,
                );

                if (key != null) {
                  final newExpense = double.tryParse(expenseController.text) ?? 0.0;
                  final newExpenseFor = expenseForController.text;
                  record['AmountExpense'] = newExpense;
                  record['Expense_for'] = newExpenseFor;
                  await _dailyupdataBox.put(key, record);
                  _loadRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Expense updated successfully',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update expense',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              child: Text(
                'Update',
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

  void filterRecords(String query) {
    setState(() {
       totalExpenses=0.0;
      if (query.isEmpty) {
        _filteredRecords = List.from(_allRecords.reversed);
      } else {
        _filteredRecords = _allRecords.where((record) {
          final customerName = record['customerName']?.toString().toLowerCase() ?? '';
          final date = record['date'] ?? '';

          bool isDateQuery = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(query);

          if (isDateQuery) {
            return date.contains(query);
          } else {
            return customerName.contains(query.toLowerCase());
          }
        }).toList().reversed.toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  bool isToday(String date) {
    try {
      final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final recordDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
      return currentDate == recordDate;
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return false;
    }
  }

  String formatDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (e) {
      debugPrint('Invalid date format: $date');
      return 'Invalid date';
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "RoznamchaRecords",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
        centerTitle: true,
        actions: [
         pdfroznamcha()
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Colors.blue, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SizedBox(
            height: 600,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Customer Name ',
                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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
                    style: TextStyle(color: Colors.black),
                    cursorColor: Colors.black,
                    onChanged: filterRecords,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
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
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            debugPrint('$totalByHand');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Expances(
                                  expanc: formattedTotalExpenses,
                                  totalByHand: totalByHand,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Expenses',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        FutureBuilder(
                          future: Hive.openBox('dailyupdata'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error loading data');
                            } else {
                              for (var record in _allRecords) {
                              
                                totalExpenses += double.tryParse(record['AmountExpense']?.toString() ?? '0.0') ?? 0.0;
                              }
                              formattedTotalExpenses = totalExpenses.toStringAsFixed(totalExpenses.truncate() == totalExpenses ? 0 : 2);
                              return Text(
                                '\$$formattedTotalExpenses',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade200,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: Hive.openBox('dailyupdata'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading data'));
                      } else {
                        double totalSalesToday = 0.0;
                        double totalByBank = 0.0;
                            totalByHand=0.0;
                        for (var record in _allRecords) {
                          final date = record['date'] as String;
                          if (isToday(date)) {
                            totalSalesToday += double.tryParse(record['totalAmount']?.toString() ?? '0.0') ?? 0.0;
                          }
                         
                            totalByBank += double.tryParse(record['amountPaidbybank']?.toString() ?? '0.0') ?? 0.0;
                           
                            totalByHand += double.tryParse(record['amountPaidbyhand']?.toString() ?? '0.0') ?? 0.0;
                          
                        }

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                      'Total byhand: \$${totalByHand.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
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
                                      'Total bybank: \$${totalByBank.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: _filteredRecords.isEmpty
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
                                  : ScrollbarTheme(
                                      data: ScrollbarThemeData(
                                        thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                                          if (states.contains(WidgetState.hovered)) {
                                            return Colors.black;
                                          }
                                          return Colors.grey.shade500;
                                        }),
                                        trackColor: WidgetStateProperty.all(Colors.transparent),
                                        trackVisibility: WidgetStateProperty.all(true),
                                        thickness: WidgetStateProperty.all(10.0),
                                      ),
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        controller: _horizontalScrollController,
                                        child: SingleChildScrollView(
                                          controller: _horizontalScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: Scrollbar(
                                            thumbVisibility: true,
                                            controller: _verticalScrollController,
                                            child: SingleChildScrollView(
                                              controller: _verticalScrollController,
                                              child: DataTable(
                                                columns: const [
                                                  DataColumn(
                                                    label: Text(
                                                      'InvoiceNO',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'KataNo',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Customer Name',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Contact Info',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Amount Paid',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                   DataColumn(
                                                    label: Text(
                                                      'byhand',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                   DataColumn(
                                                    label: Text(
                                                      'bybank',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Expense',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Expense for',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Date',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Method',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Bank',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                  DataColumn(
                                                    label: Text(
                                                      'Actions',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                rows: _filteredRecords.map((record) {
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(
                                                        Text(
                                                          '${record['InvoiceNO'] ?? 'Form Kata'}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['kataNumberController'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['customerName'] ?? 'Unknown'}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['contactInfo'] ?? 'N/A'}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['amountPaid'] ?? '0.0'}',
                                                          style: TextStyle(
                                                            color: record['paymentMethod'] == 'byBank' ? Colors.red : Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                        DataCell(
                                                        Text(
                                                          '${record['amountPaidbyhand'] ?? 0.0}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                       DataCell(
                                                        Text(
                                                          '${record['amountPaidbybank'] ?? 0.0}',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '${record['AmountExpense'] ?? 'No'}',
                                                              style: TextStyle(
                                                                color: Colors.black,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(Icons.edit, color: Colors.blue),
                                                               tooltip: "Edit",
                                                              onPressed: () => editExpense(record),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['Expense_for'] ?? 'no'}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          formatDate(record['date'] ?? ''),
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['paymentMethod'] ?? ''}',
                                                          style: TextStyle(
                                                            color: record['paymentMethod'] == 'byBank' ? Colors.red : Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Text(
                                                          '${record['Bankname'] ?? ''}',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                      DataCell(
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(Icons.delete, color: Colors.red),
                                                              onPressed: () => _deleteRecord(record),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
