import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';


class pdfroznamcha extends StatefulWidget {
  const pdfroznamcha({super.key});

  @override
  State<pdfroznamcha> createState() => _pdfroznamchaState();
}

class _pdfroznamchaState extends State<pdfroznamcha> {
  List<Map<dynamic, dynamic>> _filteredRecords = [];
  final TextEditingController _searchController = TextEditingController();
  late Box<dynamic> _dailyupdataBox;
  List<Map<dynamic, dynamic>> _allRecords = [];

  String formattedTotalExpenses = '';
  double totalByHand = 0.0;
  double totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
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
    print('All Records: $_allRecords');
    print('Filtered Records: $_filteredRecords');
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


  void _filterRecords(String query) {
    setState(() {
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
Widget build(BuildContext context) {
  return IconButton(
    icon: Icon(Icons.print, color: Colors.black),
    tooltip: "Print Records",
    splashRadius: 24,
    onPressed: () {
      _showPrintOptionsDialog(context);
    },
  );
}

void _showPrintOptionsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Select Print Range',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.today, color: Colors.blue),
              title: Text('Today\'s Records'),
              onTap: () {
                Navigator.pop(context);
                _filterAndPrintRecords('day');
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_month, color: Colors.green),
              title: Text('This Month\'s Records'),
              onTap: () {
                Navigator.pop(context);
                _filterAndPrintRecords('month');
              },
            ),
            ListTile(
              leading: Icon(Icons.all_inbox, color: Colors.purple),
              title: Text('All Records'),
              onTap: () {
                Navigator.pop(context);
                _filterAndPrintRecords('all');
              },
            ),
          ],
        ),
      );
    },
  );
}

void _filterAndPrintRecords(String timeRange) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thisMonth = DateTime(now.year, now.month, 1);

  setState(() {
    switch (timeRange) {
      case 'day':
        _filteredRecords = _allRecords.where((record) {
          try {
            final recordDate = DateTime.parse(record['date']);
            return recordDate.isAtSameMomentAs(today);
          } catch (e) {
            print('Error parsing date: ${record['date']}');
            return false;
          }
        }).toList();
        break;

      case 'month':
        _filteredRecords = _allRecords.where((record) {
          try {
            final recordDate = DateTime.parse(record['date']);
            return recordDate.year == thisMonth.year && 
                   recordDate.month == thisMonth.month;
          } catch (e) {
            print('Error parsing date: ${record['date']}');
            return false;
          }
        }).toList();
        break;

      case 'all':
        _filteredRecords = List.from(_allRecords);
        break;
    }
  });

  // Update the PDF title based on selection
  String reportTitle = timeRange == 'day' 
      ? 'Daily Roznamcha Report (${today.toString().split(' ')[0]})'
      : timeRange == 'month'
          ? 'Monthly Roznamcha Report (${DateFormat('MMMM yyyy').format(now)})'
          : 'Complete Roznamcha Report';

  generatePdf(reportTitle);
}

Future<void> generatePdf(String reportTitle) async {
  final pdf = pw.Document();
  final pwgmimge = await gmImage();
  final pwImage = await buildImage();

  // Footer widget
  pw.Widget buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey, width: 0.5)),
      ),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }

  // Header widget
  pw.Widget buildHeader() {
    return pw.Column(
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
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            reportTitle,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  // Table header
  pw.TableRow buildTableHeader() {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('Invoice', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        //  pw.Padding(
        //   padding: pw.EdgeInsets.all(8),
        //   child: pw.Text('Kata', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        // ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('ByHand', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
          pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('Bybank', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text('Method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  // Table row
  pw.TableRow buildTableRow(Map<dynamic, dynamic> record) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['date']?.toString() ?? ''),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['InvoiceNO']?.toString() ?? 'Form Kata'),
        ),
        //  pw.Padding(
        //   padding: pw.EdgeInsets.all(4),
        //   child: pw.Text(record['kataNumberController']?.toString() ?? ''),
        // ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['customerName']?.toString() ?? ''),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['amountPaid']?.toString() ?? '0'),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['amountPaidbybank']?.toString() ?? ''),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['amountPaidbybank']?.toString() ?? '', style: pw.TextStyle(color: PdfColors.red)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(4),
          child: pw.Text(record['paymentMethod']?.toString() ?? ''),
        ),
      ],
    );
  }

  // Summary widget
  pw.Widget buildSummary() {
    double totalAmountPaid = _filteredRecords.fold(0.0, 
      (sum, record) => sum + (double.tryParse(record['amountPaid']?.toString() ?? '0') ?? 0.0));
    
    double totalExpenses = _filteredRecords.fold(0.0, 
      (sum, record) => sum + (double.tryParse(record['AmountExpense']?.toString() ?? '0') ?? 0.0));

    // Calculate totals by payment method
    double totalByHand = _filteredRecords.fold(0.0, (sum, record) {
   
        return sum + (double.tryParse(record['amountPaidbyhand']?.toString() ?? '0') ?? 0.0);
     
    });

    double totalByBank = _filteredRecords.fold(0.0, (sum, record) {
   
        return sum + (double.tryParse(record['amountPaidbybank']?.toString() ?? '0') ?? 0.0);
  
    
    });



    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Summary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Total Records: ${_filteredRecords.length}'),
          pw.Text('Total Amount Paid: ${totalAmountPaid.toStringAsFixed(2)}'),
          pw.Text('Amount Paid by Hand: ${totalByHand.toStringAsFixed(2)}'),
          pw.Text('Amount Paid by Bank: ${totalByBank.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red)),
          pw.Text('Total Expenses: ${totalExpenses.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  // Add pages with limited records per page
  const int recordsPerPage = 20;
  for (int i = 0; i < _filteredRecords.length; i += recordsPerPage) {
    final pageRecords = _filteredRecords.sublist(
      i, 
      i + recordsPerPage > _filteredRecords.length 
          ? _filteredRecords.length 
          : i + recordsPerPage
    );

    pdf.addPage(
      pw.MultiPage(
        footer: (context) => buildFooter(context),
        build: (pw.Context context) => [
          buildHeader(),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: const <int, pw.TableColumnWidth>{
              0: pw.IntrinsicColumnWidth(),
              1: pw.IntrinsicColumnWidth(),
              2: pw.IntrinsicColumnWidth(),
              3: pw.IntrinsicColumnWidth(),
              4: pw.IntrinsicColumnWidth(),
              5: pw.IntrinsicColumnWidth(),
              6: pw.IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              buildTableHeader(),
              ...pageRecords.map(buildTableRow).toList(),
            ],
          ),
          // Add summary only on the last page
          if (i + recordsPerPage >= _filteredRecords.length) ...[
            pw.SizedBox(height: 20),
            buildSummary(),
          ],
        ],
      ),
    );
  }

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}
}
