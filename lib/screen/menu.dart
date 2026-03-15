import 'package:flutter/material.dart';
import 'package:sap341/screen/material_list.dart';
import 'package:sap341/screen/stock.dart';
import 'package:sap341/screen/create_so.dart';

class MainMenuScreen extends StatelessWidget {
  // Đồng bộ tông màu xanh Forest sang trọng
  final Color primaryGreen = Color.fromRGBO(27, 94, 32, 1);
  final Color accentGreen = Color(0xFF2E7D32);
  final Color backgroundLight = Color(0xFFF2F5F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          _buildSystemHeader(context), // Header chỉ có tên hệ thống
          Expanded(
            child: GridView.count(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildMenuItem(
                  context,
                  'View Material',
                  'Tra cứu danh mục vật tư',
                  Icons.inventory_2_outlined,
                  MaterialListScreen(),
                ),
                _buildMenuItem(
                  context,
                  'View Stock',
                  'Kiểm tra số lượng tồn kho',
                  Icons.warehouse_outlined,
                  StockScreen(),
                ),
                _buildMenuItem(
                  context,
                  'Create Sales Order',
                  'Tạo đơn hàng mới',
                  Icons.add_shopping_cart_rounded,
                  CreateSOScreen(),
                ),
                _buildMenuItem(
                  context,
                  'View Sales Order',
                  'Xem đơn hàng đã tạo',
                  Icons.insert_chart_outlined_rounded,
                  null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER CHỈ HIỂN THỊ TÊN HỆ THỐNG (MINIMALIST) ---
  Widget _buildSystemHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40,
        bottom: 40,
        left: 25,
        right: 25,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HỆ THỐNG BÁN HÀNG VÀ\nQUẢN LÝ TỒN KHO SAP",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900, // Đậm nét doanh nghiệp
              letterSpacing: 1.5,
              height: 1.3,
            ),
          ),
          SizedBox(height: 15),
          Container(
            height: 4,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // --- MENU ITEM CARD ---
  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget? nextScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (nextScreen != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => nextScreen),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 36, color: primaryGreen),
                Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF121212),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
