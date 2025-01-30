import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
class Expances extends StatefulWidget {
  final String expanc;
   final double totalByHand;
  const Expances({super.key, required this.expanc, required this.totalByHand});

  @override
  State<Expances> createState() => _ExpancesState();
}

class _ExpancesState extends State<Expances> {
  String external = '';
  late Box<dynamic> dailyupdataBox;
  List<Map<dynamic, dynamic>> allRecords = [];
  List<Map<dynamic, dynamic>> filteredRecords = [];
  final ScrollController horizontalScrollController = ScrollController();
  String formattedTotalExpenses = '';
  double finalexpance = 0.0;
  double totalbyhand=0.0;
  double total=0.0;
  @override
  void initState() {
    super.initState();
    external = widget.expanc;
    totalbyhand=widget.totalByHand;
    initializeBox();
  }
@override
void dispose() {
  horizontalScrollController.dispose();
  super.dispose();
}

  Future<void> initializeBox() async {
    dailyupdataBox = await Hive.openBox('expance');
    loadRecords();
  }

  void loadRecords() {
    setState(() {
      allRecords = dailyupdataBox.values.cast<Map>().toList();
      filteredRecords = List.from(allRecords.reversed);
      calculateTotalExpenses();
    });
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


  void calculateTotalExpenses() {
    double totalExpenses = 0.0;
    for (var record in allRecords) {
      totalExpenses += double.tryParse(record['AmountExpense']?.toString() ?? '0.0') ?? 0.0;
    }
    formattedTotalExpenses = totalExpenses.toStringAsFixed(totalExpenses.truncate() == totalExpenses ? 0 : 2);
    double TotalExpenses = totalExpenses;
    double exmances = double.tryParse(external.toString() ?? '0.0') ?? 0.0;
    finalexpance = TotalExpenses + exmances;
    total=totalbyhand-finalexpance;
  }

  void addExpense() {
    final TextEditingController expenseController = TextEditingController();
    final TextEditingController expenseForController = TextEditingController();
    final TextEditingController dateAddedController = TextEditingController();

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
              'Add Expense',
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
              SizedBox(height: 16),
              TextField(
                controller: dateAddedController,
                decoration: InputDecoration(
                  labelText: 'Date (yyyy-MM-dd)',
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 2.0,
                      color: Colors.black,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 2.0,
                      color: Colors.black,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 2.0,
                      color: Colors.black,
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
                    dateAddedController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
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

                final newExpense = double.tryParse(expenseController.text) ?? 0.0;
                final newExpenseFor = expenseForController.text;
                final date = dateAddedController.text;
                final newRecord = {
                  'AmountExpense': newExpense,
                  'Expense_for': newExpenseFor,
                  'date': date,
                };

                await dailyupdataBox.add(newRecord);
                loadRecords();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Expense added successfully',
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                    backgroundColor: Colors.black,
                  ),
                );
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
  void deleteExpense(Map<dynamic, dynamic> record)  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final key = dailyupdataBox.keys.firstWhere(
                  (k) => dailyupdataBox.get(k) == record,
                  orElse: () => null,
                );

                if (key != null) {
                  await dailyupdataBox.delete(key);
                  loadRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Record deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete record')),
                  );
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
 Future<void> generatePdf(List<Map<dynamic, dynamic>> records, double finalexpance, double total) async {
  final pdf = pw.Document();
  final pwImage = await buildImage();
  final pwgmimge = await gmImage();

  pdf.addPage(
    pw.MultiPage(
      header: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 50,
                  height: 50,
                  child: pwgmimge,
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Apex Solar Bannu Branch',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Back side central jail, Link Road, Bannu Township',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text("Contact:", style: pw.TextStyle(fontSize: 10)),
                    pw.Text("(0928)633753", style: pw.TextStyle(fontSize: 10)),
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
          ],
        );
      },
      build: (pw.Context context) {
        return [
          pw.Center(child: pw.Text('Expenses Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Text('Total Expenses: \$$finalexpance', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          pw.SizedBox(height: 10),
          pw.Text('Total: \$$total', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Text(' Amount_Expense', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(' Expense_for', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(' Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              ...records.map((record) {
                return pw.TableRow(
                  children: [
                    pw.Text(record['AmountExpense']?.toString() ?? 'No Data'),
                    pw.Text(record['Expense_for']?.toString() ?? 'No Data'),
                    pw.Text(record['date']?.toString() ?? 'No Data'),
                  ],
                );
              }).toList(),
            ],
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}



  void editExpense(Map<dynamic, dynamic> record) async {
    final TextEditingController expenseController = TextEditingController();
    expenseController.text = record['AmountExpense']?.toString() ?? '';
    final TextEditingController expenseForController = TextEditingController();
    expenseForController.text = record['Expense_for']?.toString() ?? '';
      final TextEditingController dateAddedController = TextEditingController();
   dateAddedController.text= record['date']?.toString() ?? '';
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
                SizedBox(height: 16),
              TextField(
                controller: dateAddedController,
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

                final key = dailyupdataBox.keys.firstWhere(
                  (k) => dailyupdataBox.get(k) == record,
                  orElse: () => null,
                );

                if (key != null) {
                  final newExpense = double.tryParse(expenseController.text) ?? 0.0;
                  final newExpenseFor = expenseForController.text;
           final date=dateAddedController.text;
                  record['AmountExpense'] = newExpense;
                  record['Expense_for'] =newExpenseFor ;
                    record['date'] = date;
                  await dailyupdataBox.put(key, record);
                  loadRecords();
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

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Text(
            'Expenses ',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      actions: [
        Row(
          children: [
            Text(
              'Add The New Expenses ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: Colors.white,
                size: 30.0,
              ),
              
              onPressed: addExpense,
               tooltip: "Add", 
              splashRadius: 24.0,
            ),
            IconButton(
              icon: Icon(
                Icons.print,
                color: Colors.white,
                size: 30.0,
              ),
               tooltip: "print ", 
              onPressed: () => generatePdf(filteredRecords, finalexpance, total),
               
              splashRadius: 24.0,
            ),
          ],
        ),
      ],
    ),
    body: Center(
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Expenses: \$$finalexpance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Total : \$$total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                'Expenses: \$$formattedTotalExpenses',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade200,
                ),
              ),
              Expanded(
                child: ScrollbarTheme(
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
                    controller: horizontalScrollController,
                    child: ListView.builder(
                      controller: horizontalScrollController, // Attach the controller here
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              record.entries.map((e) => '${e.key}: ${e.value ?? 'No Data'}').join(',  '),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                   tooltip: "Edit", 
                                  onPressed: () => editExpense(record),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                   tooltip: "Delete", 
                                  onPressed: () => deleteExpense(record),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
