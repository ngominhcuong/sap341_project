import 'package:flutter/material.dart';
import 'package:sap341/screen/material_list.dart';
import 'package:sap341/screen/stock.dart';
import 'package:sap341/screen/create_so.dart';

class MainMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SAP Inventory Management')),
      body: GridView.count(
        padding: EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _buildMenuItem(
            context,
            'Vật tư',
            Icons.inventory,
            Colors.blue,
            MaterialListScreen(),
          ),
          _buildMenuItem(
            context,
            'Tồn kho',
            Icons.warehouse,
            Colors.orange,
            StockScreen(),
          ),
          _buildMenuItem(
            context,
            'Tạo Sales Order',
            Icons.add_shopping_cart,
            Colors.green,
            CreateSOScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget nextScreen,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => nextScreen),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
