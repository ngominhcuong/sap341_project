// lib/models/sales_order_model.dart

class SalesOrderHeader {
  final String docType; // Map với ls_deep_entity-doctype
  final String salesOrg; // Map với ls_deep_entity-salesorg
  final String distChannel; // Map với ls_deep_entity-distchannel
  final String division; // Map với ls_deep_entity-division
  final String customerID; // Map với ls_deep_entity-customerid
  final List<SalesOrderItem> items; // Map với to_items

  SalesOrderHeader({
    required this.docType,
    required this.salesOrg,
    required this.distChannel,
    required this.division,
    required this.customerID,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'DocType': docType,
      'SalesOrg': salesOrg,
      'DistChannel': distChannel,
      'Division': division,
      'CustomerID': customerID,
      'to_items': items
          .map((i) => i.toJson())
          .toList(), // Tên phải khớp 'to_items'
    };
  }
}

class SalesOrderItem {
  final String itemNo; // vd: '000010'
  final String materialID;
  final String plant;
  final double quantity;

  SalesOrderItem({
    required this.itemNo,
    required this.materialID,
    required this.plant,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'ItemNo': itemNo,
      'MaterialID': materialID,
      'Plant': plant,
      'Quantity': quantity.toString(),
    };
  }
}
