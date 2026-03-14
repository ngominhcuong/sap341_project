import 'package:flutter/material.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Stock.dart';

class StockScreen extends StatelessWidget {
  final String? materialID;
  final String? materialName;

  StockScreen({this.materialID, this.materialName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(materialName ?? 'Danh mục tồn kho')),
      body: FutureBuilder<List<StockModel>>(
        // Nếu materialID null, truyền chuỗi rỗng '' vào service
        future: ODataService().fetchStocks(materialID ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final stocks = snapshot.data ?? [];

          if (stocks.isEmpty) {
            return Center(child: Text('Vật tư này hiện không còn tồn kho.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.location_on, color: Colors.blue),
                  // Hiển thị mã kho (lgort) và mã nhà máy (werks)
                  title: Text('Kho: ${stock.storageLocation}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nhà máy: ${stock.plant}'),
                      Text(
                        'Vật tư: ${stock.materialName}',
                      ), // Hiện thêm tên vật tư cho dễ nhìn
                    ],
                  ),
                  trailing: Text(
                    '${stock.availableQty} ${stock.baseUnit}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: stock.availableQty > 0 ? Colors.blue : Colors.red,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
