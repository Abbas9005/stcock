import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:printing/printing.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfAmountPaid extends StatefulWidget {
  const PdfAmountPaid({super.key});

  @override
  State<PdfAmountPaid> createState() => _PdfAmountPaidState();
}

class _PdfAmountPaidState extends State<PdfAmountPaid> {
  Box? receipts;
  int i = 0;
  double totalstock = 0.0;
  double totalquet = 0.0;
  List<Map<dynamic, dynamic>> _allRecords = [];
  List<Map<dynamic, dynamic>> _filteredRecords = [];
  late Box<dynamic> _receiptsBox;

  @override
  void initState() {
    super.initState();
    _receiptsBox = Hive.box('receipts');
    _loadRecords();
    
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
        final String uniqueKey =
            '${record['kataNumberController']}';

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
            'byhandbybank': record['byhandbybank'],
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

  Future<void> _generatePdf() async {
  final pdf = pw.Document();
  final pwgmimge = await gmImage();
  final pwImage = await buildImage();

  pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 1)),
      ),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget buildHeader() {
    return pw.Column(
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
                pw.Text(
                  'Apex Solar Bannu Branch ',
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
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'Kata Summary Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pdf.addPage(
    pw.MultiPage(
      header: (context) => buildHeader(),
      footer: (context) => buildFooter(context),
      build: (context) => [
        for (var record in _filteredRecords)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Name: ${record['customerName'] ?? ''}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '  Contact: ${record['contactInfo'] ?? ''}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Kata No: ${record['kataNumberController'] ?? ''}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
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
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Invoice',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount Paid',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Balance Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Payment Method',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...record['paymentHistory']
                      .map<pw.TableRow>((payment) => pw.TableRow(
                            children: [
                              pw.Text(payment['date'] ??''),
                              pw.Text(payment['InvoiceNO']?.toString() ??''),
                              pw.Text(payment['Total']?.toString() ??''),
                              pw.Text(payment['amountPaid']?.toString() ??''),
                              pw.Text(payment['balanceAmount']?.toString() ??''),
                              pw.Text(payment['byhandbybank'] ?? ''),
                            ],
                          )),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.print, color: Colors.black),
      tooltip: "printing", // Adds a hover tooltip
  splashRadius: 24, 
      onPressed: () {
        setState(() {
          _generatePdf();
        });
      },
    );
  }
}
