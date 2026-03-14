class SalesOrderModel {
  final String? salesOrderID; // VBELN (Số SO sau khi tạo)
  final String customerID; // KUNNR
  final String materialID; // MATNR
  final double quantity; // KWMENG
  final String plant; // WERKS
  final String storageLocation; // LGORT
  final String? status; // Status trả về từ SAP
  final String? message; // Message trả về từ SAP

  SalesOrderModel({
    this.salesOrderID,
    required this.customerID,
    required this.materialID,
    required this.quantity,
    required this.plant,
    required this.storageLocation,
    this.status,
    this.message,
  });

  // Chuyển dữ liệu sang JSON để POST lên SAP SalesOrderSet
  Map<String, dynamic> toJson() {
    return {
      'CustomerID': customerID,
      'MaterialID': materialID,
      'Quantity': quantity.toString(),
      'Plant': plant,
      'StorageLocation': storageLocation,
      // Các trường mặc định thường có trong dự án SAP
      'DocType': 'OR',
      'SalesOrg': '1000',
      'DistrChan': '10',
      'Division': '00',
    };
  }

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) {
    return SalesOrderModel(
      salesOrderID: json['SalesOrderID'],
      customerID: json['CustomerID'] ?? '',
      materialID: json['MaterialID'] ?? '',
      quantity: double.tryParse(json['Quantity'].toString()) ?? 0.0,
      plant: json['Plant'] ?? '',
      storageLocation: json['StorageLocation'] ?? '',
      status: json['Status'],
      message: json['Message'],
    );
  }
}
