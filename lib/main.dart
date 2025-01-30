import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_stock/dashboard.dart';
import 'package:my_stock/register/login.dart';
import 'package:my_stock/register/register.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the window manager
  await windowManager.ensureInitialized();
  // Configure the window options
  WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(700, 600), // Set a realistic minimum window size
    size: Size(700, 768), // Default window size
    center: true, // Center the window on the screen
    title: 'Stock Management', // Title of the application
    titleBarStyle: TitleBarStyle.normal, // Use the system title bar
  );
  // Apply the window settings and make the window visible
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setResizable(false); // Disable resizing
    await windowManager.setMaximizable(false); // Disable maximization
    await windowManager.show(); // Show the window
    await windowManager.focus(); // Focus on the window
  });
  // Initialize Hive for local storage
  await Hive.initFlutter();
  final directory = await getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  // Open necessary Hive boxesexpance
   await Hive.openBox('expance');
  await Hive.openBox('stock');
  await Hive.openBox('dailyupdata');
  await Hive.openBox('receipts');
  // Run the Flutter application
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue, // Customize your theme here
      ),
      home: Register(), // Set the dashboard screen as the home page
    );
  }
}
