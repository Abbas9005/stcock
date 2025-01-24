import 'package:flutter/material.dart';
import 'package:my_stock/PaidAmount.dart';
import 'package:my_stock/Salesform.dart';
import 'package:my_stock/Roznamcha.dart';
import 'package:my_stock/register/register.dart';
// import 'package:my_stock/balanc/balance.dart';
import 'package:my_stock/stok.dart';

class DashboardScreen extends StatelessWidget {
  @override
  
  final int pendingPayments=0;
  final int completedPayments=0;

  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0), // You can adjust the height of the AppBar
          child: AppBar(
              automaticallyImplyLeading: false, 
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.green.shade100], // Light user-friendly gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
        'Main Dashboard',
        style: TextStyle(
      fontSize: 26, // A larger font size for better visibility
      fontWeight: FontWeight.bold, // Bold for prominence
      color: Colors.black, // White color for contrast and readability
      fontFamily: 'Roboto', // Modern and clean font family (make sure the font is included in your project)
        ),
      ),
       centerTitle: true,
        actions: [
          IconButton(
  icon: Icon(
    Icons.logout,
    color: Colors.redAccent, // Famous logout color
    size: 28.0, // Slightly larger for better visibility
  ),
  tooltip: "Logout", // Adds a hover tooltip
  splashRadius: 24, // Customizes the ripple effect
  onPressed: () {
    // Navigate to Registration Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Register()),
    );
  },
),

        ],
      ),
            
          ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.green.shade100], // Light user-friendly gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Center(
                  child: SizedBox(
                    height: 500,
                    width: 500,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          _buildNavButton(
                            context,
                            'Stock Management',
                            Icons.inventory,
                            [Colors.deepPurple, Colors.blue],  // Gradient color for button
                            StockManagementScreen(),
                          ),
                          _buildNavButton(
                            context,
                            'Sales Form (Raseed)',
                            Icons.receipt_long,
                            [Colors.teal, Colors.green],  // Gradient color for button
                            SalesFormScreen()
                          ),
                          _buildNavButton(
                            context,
                            'Roznamcha Records',
                            Icons.book,
                            [Colors.blueGrey, Colors.black], // Gradient color for button
                            RoznamchaRecordsScreen(),
                          ),
                          _buildNavButton(
                            context,
                            'Kata Records',
                            Icons.analytics,
                            [Colors.amber, Colors.orange], // Gradient color for button
                          AmountPaidRecords(),
      
                          ),
                         
                        ],
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

  // Helper to build navigation buttons with gradient color
  Widget _buildNavButton(
      BuildContext context, String label, IconData icon, List<Color> gradientColors, Widget screen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Make the background transparent to show gradient
          padding: const EdgeInsets.all(8.0), // Inner padding for the button content
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size(200, 200), // Set size to 2.5x2.5 inches in logical pixels (adjusted to 200x200)
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white), // Icon size
            SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


