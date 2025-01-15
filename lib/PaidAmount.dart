import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:my_stock/pdf/forpdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
class AmountPaidRecords extends StatefulWidget {
  @override
  _AmountPaidRecordsState createState() => _AmountPaidRecordsState();
}

class _AmountPaidRecordsState extends State<AmountPaidRecords> {
  final TextEditingController _searchController = TextEditingController();
  late Box<dynamic> _dailyupdataBox;
  late Box<dynamic> _receiptsBox;
  List<Map<dynamic, dynamic>> _allRecords = [];
  List<Map<dynamic, dynamic>> _filteredRecords = [];
  double realbalanec = 0.0;
  double invoiceNumber = 0.0;
  double total = 0;
  String? selectedPaymentMethod; // State variable to keep track of the selected payment method
  bool isHandSelected = false;

  // State management for editing
  Map<String, bool> _isEditing = {};
  Map<String, TextEditingController> _controllers = {};
  bool _hasChanges = false; // State variable to track changes

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _dailyupdataBox = await Hive.openBox('dailyupdata');
    _receiptsBox = await Hive.openBox('receipts'); // Open the receipts box
    _loadRecords();
  }

  String _formatDate(String date) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (e) {
      debugPrint('Invalid date format: $date');
      return 'Invalid date';
    }
  }

  Future<void> _saveTransactionData(Map<dynamic, dynamic> transactionData) async {
    final balanceAmount = transactionData['balanceAmount'] ?? 0.0;
    if (balanceAmount >= 0.0) {
      await _dailyupdataBox.put(transactionData['date'], transactionData);
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

  void _deleteRecord(Map<dynamic, dynamic> record) async {
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
                backgroundColor: Colors.grey.shade300, // Neutral color for "Cancel"
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
                backgroundColor: Colors.red.shade800, // Danger color for "Delete"
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                // Identify all matching records
                List<dynamic> keysToDelete = [];
                _receiptsBox.keys.forEach((key) {
                  var boxRecord = _receiptsBox.get(key);
                  if (boxRecord['customerName'] == record['customerName'] &&
                      boxRecord['kataNumberController'] == record['kataNumberController']) {
                    keysToDelete.add(key);
                  }
                });

                // Delete all matching records
                for (var key in keysToDelete) {
                  await _receiptsBox.delete(key);
                }

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

  void _filterRecords(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = List<Map<dynamic, dynamic>>.from(_allRecords);
      } else {
        _filteredRecords = _allRecords.where((record) {
          // Convert data to lowercase strings for case-insensitive search
          final customerName = (record['customerName'] ?? '').toString().toLowerCase();
          final kataNumber = (record['kataNumberController'] ?? '').toString().toLowerCase();
          final contactInfo = (record['contactInfo'] ?? '').toString().toLowerCase();
          final query_lowercase = query.toLowerCase();

          // Check if date matches the query
          bool isDateMatch = false;
          try {
            if (record['date'] != null) {
              final recordDate = _formatDate(record['date']);
              isDateMatch = recordDate.contains(query);
            }
          } catch (e) {
            debugPrint('Date parsing error: $e');
          }

          // Check payment history for matches
          bool hasMatchInPaymentHistory = false;
          if (record['paymentHistory'] != null) {
            final paymentHistory = List<Map<dynamic, dynamic>>.from(record['paymentHistory']);
            hasMatchInPaymentHistory = paymentHistory.any((payment) {
              final paymentDate = _formatDate(payment['date'] ?? '');
              return paymentDate.contains(query);
            });
          }

          // Return true if any field matches the query and balance amount is not zero or has payment history
          return (customerName.contains(query_lowercase) ||
                 kataNumber.contains(query_lowercase) ||
                 contactInfo.contains(query_lowercase) ||
                 isDateMatch ||
                 hasMatchInPaymentHistory) &&
                 (record['balanceAmount'] != 0 ||
                 ( record['paymentHistory'] != null && record['paymentHistory'].isNotEmpty));
        }).toList();
      }
    });
  }

  void _editRecord(Map<dynamic, dynamic> record) {
    final TextEditingController bankname =
        TextEditingController(text: record['Bankname']);
    final TextEditingController contactInfoController =
        TextEditingController(text: record['contactInfo']);
    final TextEditingController customerName =
        TextEditingController(text: record['customerName']);
    final TextEditingController amountPaidController =
        TextEditingController();
    final TextEditingController dateController =
        TextEditingController(text: _formatDate(record['date']));

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
                          dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
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
                  child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      final newAmountPaid = double.tryParse(amountPaidController.text) ?? 0.0;
                      debugPrint('asad$newAmountPaid');
                      if (newAmountPaid == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Plz Enter The New AmountPaid'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                        return;
                      }
                      // Find the existing record key
                      final key = _receiptsBox.keys.firstWhere(
                        (k) => _receiptsBox.get(k)['customerName'] == record['customerName'] &&
                            _receiptsBox.get(k)['date'] == record['date'],
                        orElse: () => null,
                      );

                      if (key != null) {
                        // Update payment history
                        List<Map<dynamic, dynamic>> paymentHistory = [];
                        if (record['paymentHistory'] != null) {
                          paymentHistory = List<Map<dynamic, dynamic>>.from(record['paymentHistory']);
                        }
                        // balanceAmount
                        final existingBalanceAmount = paymentHistory.fold(0.0, (sum, payment) => sum + (payment['Total'] ?? 0));
                        final existingAmountPaid = paymentHistory.fold(0.0, (sum, payment) => sum + (payment['amountPaid'] ?? 0));
                        final updatedAmountPaid = newAmountPaid;
                        final updatedBalanceAmount = existingBalanceAmount - existingAmountPaid - newAmountPaid;
                        Map<String, dynamic> newPayment = {
                          'customerName': customerName.text,
                          'Bankname': bankname.text,
                          'contactInfo': contactInfoController.text,
                          'date': dateController.text,
                          'amountPaid': updatedAmountPaid,
                          'byhandbybank': isHandSelected ? 'by Hand' : 'byBank',
                          'balanceAmount': updatedBalanceAmount,
                          'kataNumberController': record['kataNumberController'],
                        };

                        paymentHistory.add(newPayment);

                        String dailyKey = '${dateController.text}_${DateTime.now().millisecondsSinceEpoch}';
                        await _dailyupdataBox.put(dailyKey, newPayment);
                        await _receiptsBox.put(dailyKey, newPayment);
                        _loadRecords();
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Record updated successfully'),
                            backgroundColor: Colors.green.shade800,
                          ),
                        );
                        // Generate receipt
                        await _generateReceipt(newPayment);
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
                  child: Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _loadRecords() {
    setState(() {
      // Initial load and sort
      _allRecords = _receiptsBox.values.cast<Map>().toList();
      _allRecords.sort((a, b) {
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
      for (var record in _allRecords) {
        final String uniqueKey = '${record['customerName']}_${record['kataNumberController']}';

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
                'byhandbybank': record['byhandbybank'],
                'InvoiceNO': record['InvoiceNO'],
                'Total': record['Total'],
              }
            ]
          };
        } else {
          var existingRecord = uniqueRecords[uniqueKey]!;
          List<dynamic> paymentHistory = List.from(existingRecord['paymentHistory'] ?? []);

          // Check for duplicate payment
          bool isDuplicatePayment = paymentHistory.any((payment) =>
            payment['date'] == record['date']
            &&
            payment['amountPaid'] == record['amountPaid']
          );

          // if (!isDuplicatePayment) {
            // Add new payment to history
            paymentHistory.add({
              'date': record['date'],
              'amountPaid': record['amountPaid'],
              'balanceAmount': record['balanceAmount'],
              'byhandbybank': record['byhandbybank'],
              'InvoiceNO': record['InvoiceNO'],
              'Total': record['Total'],
            });

            // Update running totals
            double totalAmountPaid = paymentHistory.fold(0.0,
              (sum, payment) => sum + (payment['amountPaid'] ?? 0));

            // Ensure 'Total' is not null
            double totalBalanceAmount = (record['Total'] ?? 0.0);

            // Sort payment history
            paymentHistory.sort((a, b) {
              try {
                return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
              } catch (e) {
                debugPrint('Date parsing error: $e');
                return 0;
              }
            });

            // Update record
            uniqueRecords[uniqueKey] = {
              ...record,
              // 'amountPaid': totalAmountPaid,
              // 'balanceAmount': totalBalanceAmount,
              'paymentHistory': paymentHistory,
            };
          // }
        }
      }

      // Filter records
      _allRecords = uniqueRecords.values.where((record) {
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
      _allRecords.sort((a, b) {
        try {
          return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
        } catch (e) {
          debugPrint('Date parsing error: $e');
          return 0;
        }
      });
      _filteredRecords = List<Map<dynamic, dynamic>>.from(_allRecords);

      // Debug prints
      debugPrint('All Records: $_allRecords');
      debugPrint('Filtered Records: $_filteredRecords');
    });
  }

Future<void> _generateReceipt(Map<dynamic, dynamic> record) async {
  final customerName = record['customerName'];
  final contactInfo = record['contactInfo'];
  final amountPaid = record['amountPaid'];
  final balanceAmount = record['balanceAmount'];
  final date = record['date'];
  final byhandbybank = record['byhandbybank'];
  final kataNumberController = record['kataNumberController'];
  final invoiceNO = record['InvoiceNO'];
  final total = record['Total'];
  final bankname = record['Bankname'];
  final pwgmimge = await gmImage();
  final pwImage = await buildImage();

  // Debug print to verify paymentHistory
  debugPrint('Payment History: ${record['paymentHistory']}');

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
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            'Back side central jail, Link Road, Bannu Township',
                            style: pw.TextStyle(fontSize: 10)),
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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Bill To: $customerName', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('kataNumber: $kataNumberController', style: pw.TextStyle(fontSize: 12)),
                    pw.Text('Date: $date', style: pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Row(children: [
                  pw.Text("CustomerNumber: $contactInfo", style: pw.TextStyle(fontSize: 12)),
                ]),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: const <int, pw.TableColumnWidth>{
                    0: pw.IntrinsicColumnWidth(),
                    1: pw.IntrinsicColumnWidth(),
                    2: pw.IntrinsicColumnWidth(),
                    3: pw.IntrinsicColumnWidth(),
                    4: pw.IntrinsicColumnWidth(),
                    5: pw.IntrinsicColumnWidth(),
                  },
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children:  [
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('InvoiceNO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Amount Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Balance Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: pw.EdgeInsets.all(8), child: pw.Text('Payment Method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    // Payment history rows
                    if (record['paymentHistory'] != null)
                      ...(record['paymentHistory'] as List).map((payment) {
                        final date = payment['date'] ?? 'N/A';
                        final InvoiceNO = payment['InvoiceNO'] ?? 'N/A';
                        final Total = payment['Total'] ?? 'N/A';
                        final amountPaid = payment['amountPaid'] ?? 'N/A';
                        final balanceAmount = payment['balanceAmount'] ?? 'N/A';
                        final byhandbybank = payment['byhandbybank'] ?? 'N/A';

                        // Debug prints to verify data
                        debugPrint('Date: $date');
                        debugPrint('InvoiceNO: $InvoiceNO');
                        debugPrint('Total: $Total');
                        debugPrint('Amount Paid: $amountPaid');
                        debugPrint('Balance Amount: $balanceAmount');
                        debugPrint('Payment Method: $byhandbybank');

                        return pw.TableRow(
                          children: [
                            pw.Text(date, style: pw.TextStyle(fontSize: 10)),
                            pw.Text(InvoiceNO, style: pw.TextStyle(fontSize: 10)),
                            pw.Text(Total.toString(), style: pw.TextStyle(fontSize: 10)),
                            pw.Text(amountPaid.toString(), style: pw.TextStyle(fontSize: 10)),
                            pw.Text(balanceAmount.toString(), style: pw.TextStyle(fontSize: 10)),
                            pw.Text(byhandbybank, style: pw.TextStyle(fontSize: 10)),
                          ],
                        );
                      }).toList(),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  byhandbybank == 'by Hand' ? 'Payment Method: by Hand' : 'Payment Method: by Bank',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Amount Paid: $amountPaid', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Bankname : $bankname', style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Balance Amount: $balanceAmount', style: pw.TextStyle(fontSize: 10)),
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
                        pw.Text("Head office:", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Naseer Abad Stop,", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Opp Kohinoor Mills, Peshawar Road", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Rawalpindi,", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Website: www.gmsolar.com.pk", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Email: gmainoor_afridi@yahoo.com", style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.SizedBox(height: 10, width: 150),
                    pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text("SIGNATURE:______________",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text("Gudam Bannu Link Road Behind", style: pw.TextStyle(fontSize: 10)),
                        pw.Text("Bannu Jail, KPK", style: pw.TextStyle(fontSize: 10)),
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

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Receipt saved and printed successfully!")),
    );
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
        title: Text("Kata Records", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
         actions: [
         pdffor()
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            width: 650,
            height: 700,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
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
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                    style: TextStyle(
                      color: Colors.teal.shade900,
                      fontSize: 16,
                    ),
                    cursorColor: Colors.teal.shade800,
                    onChanged: _filterRecords,
                  ),
                ),
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(child: Text('No matching records found'))
                      : ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            List<Map<dynamic, dynamic>> paymentHistory =
                                record['paymentHistory'] != null
                                    ? List<Map<dynamic, dynamic>>.from(record['paymentHistory'])
                                    : [];
                            invoiceNumber = record['InvoiceNO'] ?? 0.0; // Ensure invoiceNumber is a double
                            total = record['Total'] ?? 0.0; // Ensure total is a double

                            // Aggregate data for the record
                            double totalAmountPaid = paymentHistory.fold(0.0, (sum, payment) => sum + (payment['amountPaid'] ?? 0));

                            double totals= paymentHistory.fold(0.0, (sum, payment) => sum + (payment['Total'] ?? 0));
                            double totalBalanceAmount = totals-totalAmountPaid;
                            String paymentMethods = paymentHistory.map((payment) => payment['byhandbybank'] ?? '').join(', ');

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
                                          Center(child: Text('Customer Name: ', style: TextStyle(fontWeight: FontWeight.bold))),
                                          Text(record['customerName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 100),
                                            child: Center(child: Text('Contact Info: ',  style: TextStyle(fontWeight: FontWeight.bold))),
                                          ),
                                          Text(record['contactInfo'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Padding(
                                            padding:  EdgeInsets.only(left: 50),
                                            child: Text('Kata No: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Text(record['kataNumberController'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    // Replace the existing Table widget code with this:
                                    Table(
                                      border: TableBorder.all(),
                                      columnWidths: const <int, TableColumnWidth>{
                                        0: IntrinsicColumnWidth(),
                                        1: IntrinsicColumnWidth(),
                                        2: IntrinsicColumnWidth(),
                                        3: IntrinsicColumnWidth(),
                                        4: IntrinsicColumnWidth(),
                                        5: IntrinsicColumnWidth(),
                                      },
                                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                      children: [
                                        // Header row
                                        TableRow(
                                          decoration: BoxDecoration(color: Colors.grey[200]),
                                          children: const [
                                            Padding(padding: EdgeInsets.all(8), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Amount Paid', style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Balance Amount', style: TextStyle(fontWeight:FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                        if (record['paymentHistory'] != null)
                                          ...List<TableRow>.from(
                                            (record['paymentHistory'] as List).map((payment) {
                                              final dateKey = '${payment['date']}_date';
                                              final totalKey = '${payment['Total']}';

                                              // Initialize controllers if not already initialized
                                              if (!_controllers.containsKey(dateKey)) {
                                                _controllers[dateKey] = TextEditingController(text: _formatDate(payment['date'] ?? ''));
                                              }
                                              if (!_controllers.containsKey(totalKey)) {
                                                _controllers[totalKey] = TextEditingController(text:payment['Total']?.toString() ?? '');
                                              }

                                              // Initialize _isEditing if not already initialized
                                              if (!_isEditing.containsKey(dateKey)) {
                                                _isEditing[dateKey] = false;
                                              }
                                              if (!_isEditing.containsKey(totalKey)) {
                                                _isEditing[totalKey] = false;
                                              }
                                              // Check if InvoiceNO is present
                                              bool isInvoicePresent = payment['InvoiceNO'] != null && payment['InvoiceNO']?.toString().isNotEmpty == true;

                                              return TableRow(
                                                children: [
                                                  GestureDetector(
                                                    onTap: isInvoicePresent
                                                        ? () {
                                                            print('Date field tapped'); // Debugging print statement
                                                            setState(() {
                                                            _editExpense(record);
                                                            });
                                                          }
                                                        : null,
                                                    child: _isEditing[dateKey]! && isInvoicePresent
                                                        ? Padding(
                                                            padding: EdgeInsets.all(8),
                                                            child: TextField(
                                                              controller: _controllers[dateKey],
                                                              onSubmitted: (value) {
                                                                
                                                              },
                                                            ),
                                                          )
                                                        : Padding(
                                                            padding: EdgeInsets.all(8),
                                                            child: Text(_formatDate(payment['date'] ?? '')),
                                                          ),
                                                  ),
                                                  Padding(padding: EdgeInsets.all(8), child: Text(payment['InvoiceNO']?.toString() ?? '')),
                                                  GestureDetector(
                                                    onTap: isInvoicePresent
                                                        ? () {
                                                            setState(() {
                                                          _editExpense(record);
                                                            });
                                                          }
                                                        : null,
                                                    child: _isEditing[totalKey]! && isInvoicePresent
                                                        ? Padding(
                                                            padding: EdgeInsets.all(8),
                                                            child: TextField(
                                                              controller: _controllers[totalKey],
                                                              onSubmitted: (value) {
                                                                debugPrint('Total submitted: $value'); // Debugging print statement
                                                               
                                                              },
                                                            ),
                                                          )
                                                        : Padding(
                                                            padding: EdgeInsets.all(8),
                                                            child: Text(payment['Total']?.toString() ?? ''),
                                                          ),
                                                  ),
                                                  Padding(padding: EdgeInsets.all(8), child: Text(payment['amountPaid']?.toString() ?? '')),
                                                  Padding(padding: EdgeInsets.all(8), child: Text(payment['balanceAmount']?.toString() ?? '')),
                                                  Padding(padding: EdgeInsets.all(8), child: Text(payment['byhandbybank'] ?? '')),
                                                ],
                                              );
                                            }).toList(),
                                          ),

                                        TableRow(
                                          decoration: BoxDecoration(color: Colors.grey[200]),
                                          children: [
                                            Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text('')),
                                            Padding(padding: EdgeInsets.all(8), child: Text('$totals', style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text(totalAmountPaid.toString(), style: TextStyle(fontWeight: FontWeight.bold))),
                                            Padding(padding: EdgeInsets.all(8), child: Text(totalBalanceAmount.toString(), style: TextStyle(fontWeight: FontWeight.bold))), //totalBalanceAmount.toString()
                                            Padding(padding: EdgeInsets.all(8), child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
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
                                          color: totals == 0
                                              ? Colors.grey.shade400
                                              : Colors.teal.shade800,
                                          onPressed: totals == 0
                                              ? null
                                              : () => _editRecord(record),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          color: Colors.red.shade600,
                                          onPressed: () => _deleteRecord(record),
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
 void _editExpense(Map<dynamic, dynamic> record) async {
  final TextEditingController date = TextEditingController();
  date.text = record['date']?.toString() ?? '';
  final TextEditingController totel = TextEditingController();
  totel.text = record['Total']?.toString() ?? ''; // Ensure Total is treated as a string

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
            'Edit Total',
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
              controller: totel,
              decoration: InputDecoration(
                labelText: 'Total',
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
              controller: date,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Date',
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

              // Find the existing record key
              final key = _dailyupdataBox.keys.firstWhere(
                (k) => _dailyupdataBox.get(k)['customerName'] == record['customerName'] &&
                    _dailyupdataBox.get(k)['date'] == record['date'],
                orElse: () => null,
              );

              if (key != null) {
                final newDate = date.text; // Ensure date is treated as a string
                final newTotal = totel.text; // Ensure Total is treated as a string

                // Update payment history
                List<Map<dynamic, dynamic>> paymentHistory = [];
                if (record['paymentHistory'] != null) {
                  paymentHistory = List<Map<dynamic, dynamic>>.from(record['paymentHistory']);
                }
               paymentHistory.add({
  'date': newDate,
  'Total': newTotal,
  'amountPaid': record['amountPaid'],
  'balanceAmount': record['balanceAmount'],
  'byhandbybank': record['byhandbybank'],
  'InvoiceNO': record['InvoiceNO'],
});

                record['paymentHistory'] = paymentHistory;

                // Update the record in the Hive box
                record['date'] = newDate;
                record['Total'] = newTotal;
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

}
