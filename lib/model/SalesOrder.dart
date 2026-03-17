// lib/models/sales_order_model.dart

class SalesOrderHeader {
  final String orderId; // Để hứng mã SO trả về từ SAP
  final String doctype;
  final String salesorg;
  final String distchannel;
  final String division;
  final String customerid;
  final List<SalesOrderItem> toItems;

  SalesOrderHeader({
    this.orderId = '',
    this.doctype = 'OR',
    this.salesorg = 'UE00',
    this.distchannel = 'WH',
    this.division = 'AS',
    required this.customerid,
    required this.toItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'Orderid': orderId, // Thêm field này để SAP có chỗ trả về ID
      'Doctype': doctype,
      'Salesorg': salesorg,
      'Distchannel': distchannel,
      'Division': division,
      'Customerid': customerid,
      'To_Items': toItems.map((i) => i.toJson()).toList(),
    };
  }

  // Hứng kết quả trả về sau khi POST thành công
  factory SalesOrderHeader.fromJson(Map<String, dynamic> json) {
    var list = json['To_Items'] as List? ?? [];
    return SalesOrderHeader(
      orderId: json['Orderid'] ?? '',
      doctype: json['Doctype'] ?? '',
      salesorg: json['Salesorg'] ?? '',
      customerid: json['Customerid'] ?? '',
      toItems: list.map((i) => SalesOrderItem.fromJson(i)).toList(),
    );
  }
}

class SalesOrderItem {
  final String itemno;
  final String materialid;
  final String plant;
  final String quantity; // Để String cho an toàn với ABAP
  final String baseUnit; // Thêm để dùng cho bước Goods Issue

  SalesOrderItem({
    required this.itemno,
    required this.materialid,
    this.plant = '1000',
    required this.quantity,
    this.baseUnit = 'PC',
  });

  Map<String, dynamic> toJson() {
    return {
      'Itemno': itemno,
      'Materialid': materialid,
      'Plant': plant,
      'Quantity': quantity,
    };
  }

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      itemno: json['Itemno'] ?? '',
      materialid: json['Materialid'] ?? '',
      plant: json['Plant'] ?? '',
      quantity: json['Quantity']?.toString() ?? '0',
      baseUnit: json['Meins'] ?? 'PC', // Nếu SAP trả về đơn vị tính
    );
  }
}
