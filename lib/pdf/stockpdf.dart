import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class stockpdf extends StatefulWidget {
  const stockpdf({super.key});

  @override
  State<stockpdf> createState() => _stockpdfState();
}

class _stockpdfState extends State<stockpdf> {
  Box? stockBox;
  int i = 0;
  double totalstock = 0.0;
  double totalquet = 0.0;

  @override
  void initState() {
    super.initState();
    stockBox = Hive.box('stock');
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

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final pwgmimge = await gmImage();
    final pwImage = await buildImage();

    final stockData = stockBox?.values.toList() ?? [];
    double totalStock = 0.0;
    double totalQuantity = 0.0;
    int index = 0;

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          final pages = <pw.Widget>[];

          // Header
          pages.add(
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
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold),
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
          );

          pages.add(pw.SizedBox(height: 10));
          pages.add(
            pw.Center(
              child: pw.Text(
                'Stock Summary Report',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );
          pages.add(pw.SizedBox(height: 20));

          // Chunk stock data into groups of 20 items
          final chunks = List.generate(
            (stockData.length / 40).ceil(),
            (i) => stockData.skip(i * 40).take(40).toList(),
          );

          // Add each chunk as a separate table
          for (var chunk in chunks) {
            pages.add(
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Text('SI no',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Item Name',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Unit Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Quantity',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Data rows
                  ...chunk.map((item) {
                    final total = item['total'] ?? 0.0;
                    final quantity = item['quantity'] ?? 0.0;
                    totalStock += total;
                    totalQuantity += quantity;
                    index++;
                    return pw.TableRow(
                      children: [
                        pw.Text(' $index'),
                        pw.Text(item['itemName'] ?? 'Unnamed'),
                        pw.Text(
                            ' ${item['unitPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                        pw.Text(' ${total.toString()}'),
                        pw.Text(' ${quantity.toString()}'),
                        pw.Text(' ${item['dateAdded'] ?? 'Unknown Date'}'),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          }

          // Add total row at the end of the last page
          pages.add(
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                
                  children: [
                    pw.Text('_   ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total    ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                   
                           pw.Text('_       ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('$totalStock',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('$totalQuantity',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('_       ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );

          return pages;
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());

    // Reset totals
    totalStock = 0.0;
    totalQuantity = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.print,
        color: Colors.white,
      ),
      tooltip: "print all stock", // Adds a hover tooltip
  splashRadius: 24, 
      onPressed: _generatePdf,
    );
  }
}
