import 'package:flutter/material.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Stock.dart';

class StockScreen extends StatelessWidget {
  final String? materialID;
  StockScreen({this.materialID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết tồn kho')),
      body: FutureBuilder<List<StockModel>>(
        future: ODataService().fetchStocks(materialID ?? ''),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final stock = snapshot.data![index];
              return Card(
                color: stock.availableQty > 10 ? Colors.white : Colors.red[50],
                child: ListTile(
                  title: Text('Kho: ${stock.storageLocation}'),
                  trailing: Text(
                    '${stock.availableQty} ${stock.baseUnit}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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
