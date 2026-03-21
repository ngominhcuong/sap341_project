import 'package:flutter/material.dart';
import 'package:sap341/screen/material_list.dart';
import 'package:sap341/screen/stock.dart';
import 'package:sap341/screen/create_so.dart';
import 'package:sap341/screen/sales_order_list.dart';

class MainMenuScreen extends StatelessWidget {
  final Color primaryGreen = Color.fromRGBO(27, 94, 32, 1);
  final Color accentGreen = Color(0xFF2E7D32);
  final Color backgroundLight = Color(0xFFF2F5F2);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isNarrow = size.width < 700;

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              "assets/images/backgrsap.png",
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Column(
            children: [
              _buildSystemHeader(context),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size.width < 500 ? 2 : (isNarrow ? 2 : 4),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: size.width < 500
                        ? 0.95
                        : (isNarrow ? 1.0 : 1.2),
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final items = [
                      [
                        'View Material',
                        'Tra cứu danh mục vật tư',
                        Icons.inventory_2_outlined,
                        MaterialListScreen(),
                      ],
                      [
                        'View Stock',
                        'Kiểm tra số lượng tồn kho',
                        Icons.warehouse_outlined,
                        StockScreen(),
                      ],
                      [
                        'Create Sales Order',
                        'Tạo đơn hàng mới',
                        Icons.add_shopping_cart_rounded,
                        CreateSOScreen(),
                      ],
                      [
                        'View Sales Order',
                        'Xem đơn hàng đã tạo',
                        Icons.insert_chart_outlined_rounded,
                        SalesOrderListScreen(),
                      ],
                    ];

                    final item = items[index];
                    return _buildMenuItem(
                      context,
                      item[0] as String,
                      item[1] as String,
                      item[2] as IconData,
                      item[3] as Widget,
                    );
                  },
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ],
      ),
    );
  }

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
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
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

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget? nextScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF0F8F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryGreen.withOpacity(0.1), width: 1),
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
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 50, color: primaryGreen),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF121212),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '© SAP341 - SE1877SAP - GROUP 5 - PROJECT',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
