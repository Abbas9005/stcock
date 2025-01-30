import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Reportistock extends StatefulWidget {
  final String itemName;
  final double total;
  final String dateAdded;

  const Reportistock({super.key,
    required this.itemName,
    required this.total,
    required this.dateAdded,
  });

  @override
  State<Reportistock> createState() => _ReportistockState();
}

class _ReportistockState extends State<Reportistock> {
  Box? stockBox;
  int i = 0;
  double totalstock = 0.0;
  double totalquet = 0.0;
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
    dailyupdataBox = await Hive.openBox('dailyupdata');
    loadRecords();
  }

  void loadRecords() {
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

    setState(() {
      allRecords = records;
      filteredRecords = List.from(records.reversed);
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

  Future<void> generatePdf() async {
    final pwImage = await buildImage();
    final pwgmimge = await gmImage();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (pw.Context context) {
          return pw.Row(
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
          );
        },
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Center(child: pw.Text('Stock Register: ${widget.itemName}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            ),
            pw.Paragraph(text: 'Total sell: $totalsell', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text(' Totalstock',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    // pw.Text('Remaining stock'),
                    pw.Text('Quantity',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Unit Price',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Invoice',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(' Customer',style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Text(widget.total.toString()),
                    // pw.Text(''),
                    pw.Text(''),
                    pw.Text(''),
                    pw.Text(''),
                    pw.Text(widget.dateAdded),
                    pw.Text(''),
                    pw.Text(''),
                  ],
                ),
                ...filteredRecords.reversed.map((record) {
                  final item = record['matchedItem'];
                  final quantity = item['quantity'];
                  Remainingquantity = Remainingquantity - quantity;
                  final totalof = item['quantity'] * item['unitPrice'];
                  final  customerName=record['customerName'];

                // Debug print

                  return pw.TableRow(
                    children: [
                      pw.Text(''),
                      // pw.Text('$Remainingquantity'),
                      pw.Text( ' $quantity'),
                      pw.Text( item['unitPrice']?.toString() ?? ''),
                      pw.Text(' $totalof'),
                      pw.Text(( record['date']?.toString() ?? '')),
                      pw.Text( record['InvoiceNO']?.toString() ?? ''),
                      pw.Text( ' $customerName'),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'stock_register.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.print,
        color: Colors.black,
      ),
      tooltip: "print Record", // Adds a hover tooltip
      splashRadius: 24,
      onPressed: generatePdf,
    );
  }
}
