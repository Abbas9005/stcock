import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:my_stock/pdf/pdfamoutpaid.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AmountPaidRecords extends StatefulWidget {
  const AmountPaidRecords({super.key});

  @override
  AmountPaidRecordsState createState() => AmountPaidRecordsState();
}

class AmountPaidRecordsState extends State<AmountPaidRecords> {
  final TextEditingController searchController = TextEditingController();
  late Box<dynamic> dailyupdataBox;
  late Box<dynamic> receiptsBox;
  List<Map<dynamic, dynamic>> allRecords = [];
  List<Map<dynamic, dynamic>> filteredRecords = [];
  double realbalanec = 0.0;
  double invoiceNumber = 0.0;
  final TextEditingController totalController = TextEditingController();

  String?
      selectedPaymentMethod; // State variable to keep track of the selected payment method
  bool isHandSelected = false;

  // State management for editing
  final Map<String, bool> _isEditing = {};
  final Map<String, TextEditingController> controllers = {};
  final bool hasChanges = false; // State variable to track changes

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    dailyupdataBox = await Hive.openBox('dailyupdata');
    receiptsBox = await Hive.openBox('receipts'); // Open the receipts box
    loadRecords();
  }

  String formatDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (e) {
      debugPrint('Invalid date format: $date');
      return 'Invalid date';
    }
  }

  Future<void> saveTransactionData(
      Map<dynamic, dynamic> transactionData) async {
    final balanceAmount = transactionData['balanceAmount'] ?? 0.0;
    if (balanceAmount >= 0.0) {
      await dailyupdataBox.put(transactionData['date'], transactionData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data saved to Kata Records successfully!")),
      );
    }
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

  void deleteRecord(Map<dynamic, dynamic> record) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          backgroundColor: Colors.red.shade50, // Subtle warning background
          title: Center(
            child: Text(
              'Confirm Deletion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.red.shade800, // Strong red for emphasis
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black, // Neutral text color for readability
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly, // Center buttons
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.grey.shade300, // Neutral color for "Cancel"
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
                backgroundColor:
                    Colors.red.shade800, // Danger color for "Delete"
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                // Identify all matching records
                List<dynamic> keysToDelete = [];
                for (var key in receiptsBox.keys) {
                  var boxRecord = receiptsBox.get(key);
                  if (boxRecord['kataNumberController'] ==
                      record['kataNumberController']) {
                    keysToDelete.add(key);
                  }
                }

                // Delete all matching records
                for (var key in keysToDelete) {
                  await receiptsBox.delete(key);
                }

                loadRecords();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Record deleted successfully',
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                    backgroundColor: Colors.black,
                  ),
                );

                Navigator.of(context).pop();
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

  void filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRecords = List<Map<dynamic, dynamic>>.from(allRecords);
      } else {
        filteredRecords = allRecords.where((record) {
          // Convert data to lowercase strings for case-insensitive search
          final customerName =
              (record['customerName'] ?? '').toString().toLowerCase();
          final kataNumber =
              (record['kataNumberController'] ?? '').toString().toLowerCase();
          final contactInfo =
              (record['contactInfo'] ?? '').toString().toLowerCase();
          final queryLowercase = query.toLowerCase();

          // Check if date matches the query
          bool isDateMatch = false;
          try {
            if (record['date'] != null) {
              final recordDate = formatDate(record['date']);
              isDateMatch = recordDate.contains(query);
            }
          } catch (e) {
            debugPrint('Date parsing error: $e');
          }

          // Check payment history for matches
          bool hasMatchInPaymentHistory = false;
          if (record['paymentHistory'] != null) {
            final paymentHistory =
                List<Map<dynamic, dynamic>>.from(record['paymentHistory']);
            hasMatchInPaymentHistory = paymentHistory.any((payment) {
              final paymentDate = formatDate(payment['date'] ?? '');
              return paymentDate.contains(query);
            });
          }

          // Return true if any field matches the query and balance amount is not zero or has payment history
          return (customerName.contains(queryLowercase) ||
                  kataNumber.contains(queryLowercase) ||
                  contactInfo.contains(queryLowercase) ||
                  isDateMatch ||
                  hasMatchInPaymentHistory) &&
              (record['balanceAmount'] != 0 ||
                  (record['paymentHistory'] != null &&
                      record['paymentHistory'].isNotEmpty));
        }).toList();
      }
    });
  }

  void editRecord(Map<dynamic, dynamic> record) {
    final TextEditingController bankname =
        TextEditingController(text: record['Bankname']);
    final TextEditingController contactInfoController =
        TextEditingController(text: record['contactInfo']);
    final TextEditingController customerName =
        TextEditingController(text: record['customerName']);
    final TextEditingController amountPaidController = TextEditingController();
    final TextEditingController dateController =
        TextEditingController(text: formatDate(record['date']));

    bool isHandSelected = true; // Default to 'by Hand'

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.blueGrey.shade50,
              title: Center(
                child: Text(
                  'Edit Record',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    TextField(
                      controller: amountPaidController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'New Paid Amount',
                        labelStyle: TextStyle(color: Colors.teal.shade700),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        labelText: 'Date (yyyy-MM-dd)',
                        labelStyle: TextStyle(color: Colors.teal.shade700),
                        border: OutlineInputBorder(),
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
                          dateController.text =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                        }
                      },
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
                               bankname.text='';
                              isHandSelected = value!;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Text(
                          'by Hand',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isHandSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                        Radio<bool>(
                          value: false,
                          groupValue: isHandSelected,
                          onChanged: (value) {
                            setState(() {
                              bankname.text='';
                              isHandSelected = value!;
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                        Text(
                          'by Bank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: !isHandSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (isHandSelected == false)
                      TextField(
                        controller: bankname,
                        decoration: InputDecoration(
                          labelText: 'Bankname',
                          labelStyle: TextStyle(color: Colors.teal.shade700),
                          border: OutlineInputBorder(),
                        ),
                      ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final newAmountPaid =
                          double.tryParse(amountPaidController.text) ?? 0.0;
                      debugPrint('New Amount Paid: $newAmountPaid');
                      if (newAmountPaid == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please Enter The New Amount Paid'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                        return;
                      }

                      // Find the existing record key
                      final key = receiptsBox.keys.firstWhere(
                        (k) =>
                            receiptsBox.get(k)['customerName'] ==
                                record['customerName'] &&
                            receiptsBox.get(k)['date'] == record['date'],
                        orElse: () => null,
                      );

                      if (key != null) {
                        // Update payment history
                        List<Map<dynamic, dynamic>> paymentHistory = [];
                        if (record['paymentHistory'] != null) {
                          paymentHistory = List<Map<dynamic, dynamic>>.from(
                              record['paymentHistory']);
                        }

                        double amountPaid = paymentHistory.fold(
                          0.0,
                          (sum, payment) {
                            double? amountPaid = double.tryParse(
                                payment['amountPaid']?.toString() ?? '0');
                            if (amountPaid == null) {
                              debugPrint(
                                  'Error: Unable to parse amountPaid for payment: $payment');
                              amountPaid = 0.0;
                            }
                            return sum + amountPaid;
                          },
                        );
                        // Calculate existing balance and amount paid
                        final existingBalanceAmount =
                            paymentHistory.fold(0.0, (sum, payment) {
                          final total =
                              payment['Total'] is num ? payment['Total'] : 0.0;
                          return sum + total;
                        });

                        final updatedAmountPaid = newAmountPaid;
                        final updatedBalanceAmount = existingBalanceAmount;

//                         double totals = paymentHistory.fold(
//   0.0,
//   (sum, payment) {
//     double? total = double.tryParse(payment['Total']?.toString() ?? '0');
//     if (total == null) {
//       debugPrint('Error: Unable to parse Total for payment: $payment');
//       total = 0.0;
//     }
//     return sum + total;
//   },
// );

                        // Aggregate data for the record
                        final totalAmountPaid = paymentHistory.fold(
                            0.0,
                            (sum, payment) =>
                                sum +
                                (double.tryParse(
                                        payment['amountPaid']?.toString() ??
                                            '0') ??
                                    0.0));

                        double totals = paymentHistory.fold(
                          0.0,
                          (sum, payment) {
                            double? total = double.tryParse(
                                payment['Total']?.toString() ?? '0');
                            if (total == null) {
                              debugPrint(
                                  'Error: Unable to parse Total for payment: $payment');
                              total = 0.0;
                            }
                            return sum + total;
                          },
                        );

                        final balanceAmount = paymentHistory.fold(
                            0.0,
                            (sum, payment) =>
                                sum +
                                (double.tryParse(
                                        payment['balanceAmount']?.toString() ??
                                            '0') ??
                                    0.0));
                        double totalBalanceAmount =
                            totals - totalAmountPaid - updatedAmountPaid;

// Ensure updatedTotal is correctly calculated and used
                        double updatedTotal =
                            double.tryParse(totalController.text) ?? 0.0;

                        Map<String, dynamic> newPayment = {
                          'customerName': customerName.text,
                          'Bankname': bankname.text,
                          'contactInfo': contactInfoController.text,
                          'date': dateController.text,
                          'amountPaid': updatedAmountPaid,
                             'amountPaidbyhand': isHandSelected? updatedAmountPaid:'',
                            'amountPaidbybank':isHandSelected?'': updatedAmountPaid,
                          'paymentMethod': isHandSelected ? 'by Hand' : 'byBank',
                          'balanceAmount': totalBalanceAmount,
                          'kataNumberController':
                              record['kataNumberController'],
                          'Total': updatedTotal, // Ensure this is set correctly
                        };

                        paymentHistory.add(newPayment);

                        String dailyKey =
                            '${dateController.text}_${DateTime.now().millisecondsSinceEpoch}';
                        await dailyupdataBox.put(dailyKey, newPayment);
                        await receiptsBox.put(dailyKey, newPayment);
                        loadRecords();
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Record updated successfully'),
                            backgroundColor: Colors.green.shade800,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error updating record: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating record: $e'),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    }
                  },
                  child: Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void loadRecords() {
    setState(() {
      // Initial load and sort
      allRecords = receiptsBox.values.cast<Map>().toList();
      allRecords.sort((a, b) {
        try {
          return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
        } catch (e) {
          debugPrint('Date parsing error: $e');
          return 0;
        }
      });

      // Single map for unique records
      Map<String, Map<dynamic, dynamic>> uniqueRecords = {};

      // Process all records once
      for (var record in allRecords) {
        final String uniqueKey = '${record['kataNumberController']}';

        if (!uniqueRecords.containsKey(uniqueKey)) {
          uniqueRecords[uniqueKey] = {
            ...record,
            'InvoiceNO': record['InvoiceNO'],
            'Total': record['Total'],
            'paymentHistory': [
              {
                'date': record['date'],
                'amountPaid': record['amountPaid'],
                'balanceAmount': record['balanceAmount'],
                'paymentMethod': record['paymentMethod'],
                'InvoiceNO': record['InvoiceNO'],
                'Total': record['Total'],
              }
            ]
          };
        } else {
          var existingRecord = uniqueRecords[uniqueKey]!;
          List<dynamic> paymentHistory =
              List.from(existingRecord['paymentHistory'] ?? []);

          // Check for duplicate payment
          bool isDuplicatePayment = paymentHistory.any((payment) =>
              payment['date'] == record['date'] &&
              payment['amountPaid'] == record['amountPaid']);

          // if (!isDuplicatePayment) {
          // Add new payment to history
          paymentHistory.add({
            'date': record['date'],
            'amountPaid': record['amountPaid'],
            'balanceAmount': record['balanceAmount'],
            'paymentMethod': record['paymentMethod'],
            'InvoiceNO': record['InvoiceNO'],
            'Total': record['Total'],
          });

          // Update running totals
          double totalAmountPaid = paymentHistory.fold(
              0.0,
              (sum, payment) =>
                  sum +
                  (double.tryParse(payment['amountPaid']?.toString() ?? '0') ??
                      0.0));

          // Ensure 'Total' is not null
          double totalBalanceAmount;
          try {
            totalBalanceAmount = double.parse(record['Total'] ?? '0.0');
          } catch (e) {
            totalBalanceAmount = 0.0; // Fallback in case of parsing failure
          }

          // Sort payment history
          paymentHistory.sort((a, b) {
            try {
              return DateTime.parse(b['date'])
                  .compareTo(DateTime.parse(a['date']));
            } catch (e) {
              debugPrint('Date parsing error: $e');
              return 0;
            }
          });

          // Update record
          uniqueRecords[uniqueKey] = {
            ...record,
            //  'amountPaid': totalAmountPaid,
            // // 'balanceAmount': totalBalanceAmount,
            'paymentHistory': paymentHistory,
          };
          // }
        }
      }

      // Filter records
      allRecords = uniqueRecords.values.where((record) {
        try {
          return record['balanceAmount'] != 0 ||
              (record['balanceAmount'] == 0 &&
                  record['paymentHistory'] != null &&
                  record['paymentHistory'].isNotEmpty);
        } catch (e) {
          debugPrint('Error filtering records: $e');
          return false;
        }
      }).toList();

      // Final sort and update filtered records
      allRecords.sort((a, b) {
        try {
          return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
        } catch (e) {
          debugPrint('Date parsing error: $e');
          return 0;
        }
      });
      filteredRecords = List<Map<dynamic, dynamic>>.from(allRecords);

      // Debug prints
      debugPrint('All Records: $allRecords');
      debugPrint('Filtered Records: $filteredRecords');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Kata Records", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: const [PdfAmountPaid()],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 650,
            height: 700,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Name and by KataNo',
                      labelStyle: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.teal.shade700,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.teal.shade800,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.blueGrey.shade50,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                    style: TextStyle(
                      color: Colors.teal.shade900,
                      fontSize: 16,
                    ),
                    cursorColor: Colors.teal.shade800,
                    onChanged: filterRecords,
                  ),
                ),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? Center(child: Text('No matching records found'))
                      : ListView.builder(
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            List<Map<dynamic, dynamic>> paymentHistory =
                                record['paymentHistory'] != null
                                    ? List<Map<dynamic, dynamic>>.from(
                                        record['paymentHistory'])
                                    : [];
                            invoiceNumber = record['InvoiceNO'] ??
                                0.0; // Ensure invoiceNumber is a double
                            String? totalString = record['Total']?.toString();

                            double? total;

                            if (totalString != null) {
                              total = double.tryParse(totalString);
                              if (total == null) {
                                // Handle the case where the conversion failed
                                print(
                                    'Error: Unable to convert "$totalString" to a double.');
                              }
                            } else {
                              // Handle the case where record['Total'] is null
                              print('Error: record["Total"] is null.');
                            }

                            // Aggregate data for the record
                            final AmountPaidbyhand = paymentHistory.fold(
                                0.0,
                                (sum, payment) =>
                                    sum +
                                    (double.tryParse(
                                            payment['amountPaid']?.toString() ??
                                                '0') ??
                                        0.0));
                            final AmountPaidbybank = paymentHistory.fold(
                                0.0,
                                (sum, payment) =>
                                    sum +
                                    (double.tryParse(payment['amountPaidbybank']
                                                ?.toString() ??
                                            '0') ??
                                        0.0));

                            double totals = paymentHistory.fold(
                              0.0,
                              (sum, payment) {
                                double? total = double.tryParse(
                                    payment['Total']?.toString() ?? '0');
                                if (total == null) {
                                  debugPrint(
                                      'Error: Unable to parse Total for payment: $payment');
                                  total = 0.0;
                                }
                                return sum + total;
                              },
                            );
                            final totalAmountPaid =
                                AmountPaidbyhand + AmountPaidbybank;

                            final balanceAmount = paymentHistory.fold(
                                0.0,
                                (sum, payment) =>
                                    sum +
                                    (double.tryParse(payment['balanceAmount']
                                                ?.toString() ??
                                            '0') ??
                                        0.0));
                            double totalBalanceAmount =
                                totals - totalAmountPaid;

                            String paymentMethods = paymentHistory
                                .map((payment) => payment['paymentMethod'] ?? '')
                                .join(', ');
                            return Card(
                              elevation: 5,
                              margin: EdgeInsets.all(8),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SingleChildScrollView(
                                      // controller: _horizontalScrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Text('Name: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(record['customerName'] ?? '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Center(
                                              child: Text('    Contact: ',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))),
                                          Text(record['contactInfo'] ?? '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text('    Kata No: ',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                              record['kataNumberController'] ??
                                                  '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    // Replace the existing Table widget code with this:
                                    Table(
                                      border: TableBorder.all(),
                                      columnWidths: const <int,
                                          TableColumnWidth>{
                                        0: IntrinsicColumnWidth(),
                                        1: IntrinsicColumnWidth(),
                                        2: IntrinsicColumnWidth(),
                                        3: IntrinsicColumnWidth(),
                                        4: IntrinsicColumnWidth(),
                                        5: IntrinsicColumnWidth(),
                                      },
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: [
                                        // Header row
                                        TableRow(
                                          decoration: BoxDecoration(
                                              color: Colors.grey[200]),
                                          children: const [
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Date',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Invoice',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Total',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Amount Paid',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Balance Amount',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Payment Method',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                          ],
                                        ),
                                        if (record['paymentHistory'] != null)
                                          ...List<TableRow>.from(
                                            (record['paymentHistory'] as List)
                                                .map((payment) {
                                              final dateKey =
                                                  '${payment['date']}_date';
                                              final totalKey =
                                                  '${payment['Total']}';

                                              // Initialize _isEditing if not already initialized

                                              // Check if InvoiceNO is present
                                              bool isInvoicePresent =
                                                  payment['InvoiceNO'] !=
                                                          null &&
                                                      payment['InvoiceNO']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true;

                                              return TableRow(
                                                children: [
                                                  GestureDetector(
                                                    onTap: isInvoicePresent
                                                        ? () async {
                                                            print(
                                                                'Date field tapped'); // Debugging print statement
                                                            // Wait for the update
                                                            setState(() {
                                                              // Reload the updated data from Hive
                                                              final key =
                                                                  record['key'];
                                                              print(
                                                                  'Key: $key'); // Debugging print statement
                                                              final updatedRecord =
                                                                  dailyupdataBox
                                                                      .get(key);
                                                              print(
                                                                  'Updated Record: $updatedRecord'); // Debugging print statement
                                                              if (updatedRecord !=
                                                                  null) {
                                                                record.addAll(
                                                                    updatedRecord);
                                                              }
                                                            });
                                                          }
                                                        : null,
                                                    child: (_isEditing[
                                                                    dateKey] ??
                                                                false) &&
                                                            isInvoicePresent
                                                        ? Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8),
                                                            child: TextField(
                                                              controller:
                                                                  controllers[
                                                                      dateKey],
                                                              onSubmitted:
                                                                  (value) {
                                                                debugPrint(
                                                                    'Date submitted: $value');
                                                              },
                                                            ),
                                                          )
                                                        : Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8),
                                                            child: Text(formatDate(
                                                                payment['date'] ??
                                                                    '')),
                                                          ),
                                                  ),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      child: Text(payment[
                                                                  'InvoiceNO']
                                                              ?.toString() ??
                                                          '')),
                                                  GestureDetector(
                                                    onTap: isInvoicePresent
                                                        ? () {
                                                            setState(() {});
                                                          }
                                                        : null,
                                                    child: _isEditing[
                                                                totalKey] ??
                                                            false &&
                                                                isInvoicePresent
                                                        ? Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8),
                                                            child: TextField(
                                                              controller:
                                                                  controllers[
                                                                      totalKey],
                                                              onSubmitted:
                                                                  (value) {
                                                                debugPrint(
                                                                    'Total submitted: $value'); // Debugging print statement
                                                              },
                                                            ),
                                                          )
                                                        : Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8),
                                                            child: Text(payment[
                                                                        'Total']
                                                                    ?.toString() ??
                                                                ''),
                                                          ),
                                                  ),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      child: Text(payment[
                                                                  'amountPaid']
                                                              ?.toString() ??
                                                          '')),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      child: Text(payment[
                                                                  'balanceAmount']
                                                              ?.toString() ??
                                                          '')),
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.all(8),
                                                      child: Text(payment[
                                                              'paymentMethod'] ??
                                                          '')),
                                                ],
                                              );
                                            }).toList(),
                                          ),

                                        TableRow(
                                          decoration: BoxDecoration(
                                              color: Colors.grey[200]),
                                          children: [
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('Total',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('')),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('$totals',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text(
                                                    totalAmountPaid.toString(),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text(
                                                    totalBalanceAmount
                                                        .toString(),
                                                    style: TextStyle(
                                                        fontWeight: FontWeight
                                                            .bold))), //totalBalanceAmount.toString()
                                            Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          tooltip: "Edit",
                                          color: totals == 0
                                              ? Colors.grey.shade400
                                              : Colors.teal.shade800,
                                          onPressed: totals == 0
                                              ? null
                                              : () => editRecord(record),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          tooltip: "Delete",
                                          color: Colors.red.shade600,
                                          onPressed: () => deleteRecord(record),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
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
