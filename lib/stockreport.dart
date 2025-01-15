import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_stock/istakreport.dart';
import 'package:my_stock/register/register.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StockReport extends StatefulWidget {
  @override
  _StockReportState createState() => _StockReportState();
}

class _StockReportState extends State<StockReport> {
  Box? stockBox;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  int? tappedIndex; // State variable to keep track of the tapped cell index
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
      int i=0;
      double totalstock=0.0;
      double totalquet=0.0;
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
  // Function to handle deletion of a stock item with confirmation
  void _deleteStockItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.9), // Danger background color
          title: Center(
            child: Text(
              'Delete Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this item?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceAround, // Center the buttons
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Strong contrast button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                setState(() {
                  stockBox?.deleteAt(index);
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Yes',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Cancel button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(
                  color: Colors.black,
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

  void _editStockItem(int index) {
    final item = stockBox?.getAt(index);

    if (item != null) {
      TextEditingController nameController =
          TextEditingController(text: item['itemName']);
      TextEditingController namecatogory =
          TextEditingController(text: item['category']);
      TextEditingController priceController =
          TextEditingController(text: item['unitPrice'].toString());
      TextEditingController quantityController =
          TextEditingController(text: item['quantity'].toString());
      TextEditingController dateController =
          TextEditingController(text: item['dateAdded']);
final quantatecurinte= item['quantity'];
final stocktotal= item['total'];
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            title: Center(
              child: Text(
                'Edit Item',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.purple,
                ),
              ),
            ),
            content: Container(
              height: 300, // Adjusted height for better spacing
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Unit Price',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(
                      labelText: 'Date Added',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {

                  final quantity=quantityController.text;
                       final quantate=  double.tryParse(quantity) ?? 0.0;
                       final totalQuantity=quantate-quantatecurinte;

                        double total=stocktotal+totalQuantity;
                  setState(() {

                    stockBox?.putAt(index, {
                      'itemName': nameController.text,
                      'category': namecatogory.text,
                      'unitPrice': double.tryParse(priceController.text) ?? 0.0,
                      'quantity': int.tryParse(quantityController.text) ?? 0,
                      'dateAdded': dateController.text,
                       'total': total,
                    });
                  });
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
     final pwgmimge = await gmImage();
    final pwImage = await buildImage();

    final stockData = stockBox?.values.toList() ?? [];

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
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
                pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Stock Summary Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                     decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                       pw.Text('SI no', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                 

                  ...stockData.map((item) {
             final  total=item['total'];
            final quantity = item['quantity'];
                      totalstock=totalstock+total;
                      totalquet=totalquet+quantity;
                    i++;
                    return pw.TableRow(
                      children: [
                         pw.Text(' $i'),
                        pw.Text(item['itemName'] ?? 'Unnamed'),
                        pw.Text(' ${item['unitPrice']?.toStringAsFixed(2) ?? '0.00'}'),
                        pw.Text(' ${item['total']?.toString() ?? '0'}'),
                        pw.Text(' ${item['quantity']?.toString() ?? '0'}'),
                        pw.Text(' ${item['dateAdded'] ?? 'Unknown Date'}'),
                      ],
                    );
                  }).toList(),

                 pw.TableRow(
                   decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                       pw.Text('', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('$totalstock', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('$totalquet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),

                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    
  totalquet=0.0;
  totalquet=0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // AppBar background color
        title: Text(
          'Stock Report',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Title text color
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by item name...',
                hintStyle: TextStyle(
                  color: Colors.teal.shade200, // Hint text color
                  fontStyle: FontStyle.italic,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // Remove the default border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.teal.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.teal.shade100,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.teal.shade50, // TextField background color
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.teal.shade600, // Prefix icon color
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
              style: TextStyle(
                color: Colors.white, // Search text color
                fontSize: 16,
              ),
              cursorColor: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.print,color: Colors.white,),
            
            onPressed: _generatePdf,
          ),
        ],
      ),
      body: Center(
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ValueListenableBuilder(
            valueListenable: Hive.box('stock').listenable(),
            builder: (context, Box box, _) {
              if (box.isEmpty) {
                return Center(
                  child: Text(
                    'No data found in the stock database.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final stockData = box.values
                  .toList()
                  .where((item) => item['itemName']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery))
                  .toList();

              return  Container(
                height: 700,
                width: 600,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [ScrollbarTheme(
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
                                  DataColumn(
                                    label: Text(
                                      'Item Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Unit Price',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Quantity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                rows: stockData.asMap().map<int, DataRow>((index, item) {
                                  final itemName = item['itemName'] ?? 'Unnamed';
                                  final category = item['category'] ?? 'Uncategory';
                                  final unitPrice = item['unitPrice'] ?? 0.0;
                                  final quantity = item['quantity'] ?? 0;
                                  final dateAdded = item['dateAdded'] ?? 'Unknown Date';
                                  final Total = item['total'] ?? 0;
                                  return MapEntry(
                                    index,
                                    DataRow(
                                      color: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (tappedIndex == index) {
                                            return Colors.yellow.withOpacity(0.5); // Change background color when tapped
                                          }
                                          return Colors.transparent; // Default background color
                                        },
                                      ),
                                      cells: [
                                        DataCell(
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                tappedIndex = index; // Update the tapped index
                                              });
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => istakfordescrption(
                                                    itemName: itemName,
                                                    total: Total,
                                                    dateAdded: dateAdded,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Center(
                                              child: Text(
                                                itemName,
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              '\Rs: ${unitPrice.toStringAsFixed(2)}',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              Total.toString(),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              quantity.toString(),
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Center(
                                            child: Text(
                                              dateAdded,
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit, color: Colors.black),
                                                onPressed: () => _editStockItem(index),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteStockItem(index),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).values.toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),]
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
