// lib/models/sales_order_model.dart

class SalesOrderHeader {
  final String doctype; // ls_deep_entity-doctype
  final String salesorg; // ls_deep_entity-salesorg
  final String distchannel; // ls_deep_entity-distchannel
  final String division; // ls_deep_entity-division
  final String customerid; // ls_deep_entity-customerid
  final List<SalesOrderItem> toItems;

  SalesOrderHeader({
    this.doctype = 'OR',
    this.salesorg = '1000',
    this.distchannel = '10',
    this.division = '00',
    required this.customerid,
    required this.toItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'Doctype': doctype,
      'Salesorg': salesorg,
      'Distchannel': distchannel,
      'Division': division,
      'Customerid': customerid,
      // Tên 'To_Items' phải khớp chính xác với Navigation Property trong SEGW
      'To_Items': toItems.map((i) => i.toJson()).toList(),
    };
  }
}

class SalesOrderItem {
  final String itemno; // ls_item-itemno (Vd: '000010')
  final String materialid; // ls_item-materialid
  final String plant; // ls_item-plant
  final double quantity; // ls_item-quantity

  SalesOrderItem({
    required this.itemno,
    required this.materialid,
    this.plant = '1000',
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'Itemno': itemno,
      'Materialid': materialid,
      'Plant': plant,
      'Quantity': quantity.toString(), // Truyền dạng String để ABAP dễ convert
    };
  }
}
