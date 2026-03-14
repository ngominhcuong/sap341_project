import 'package:flutter/material.dart';
// Import các màn hình và service của bạn (thay 'your_project_name' bằng tên project của bạn)
import 'package:sap341/screen/menu.dart';

void main() {
  runApp(const SAPInventoryApp());
}

class SAPInventoryApp extends StatelessWidget {
  const SAPInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt nhãn Debug cho đẹp
      title: 'SAP Inventory Management',

      // Thiết lập Theme màu xanh chuẩn SAP (Fiori style)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0070F2), // Màu xanh đặc trưng của SAP
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0070F2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        // Làm đẹp các nút bấm
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      // Màn hình khởi đầu là MainMenuScreen thay vì MyHomePage
      home: MainMenuScreen(),
    );
  }
}
