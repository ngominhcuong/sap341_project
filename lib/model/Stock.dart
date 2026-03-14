class StockModel {
  final String materialID; // matnr
  final String materialName; // maktx
  final String plant; // werks
  final String storageLocation; // lgort
  final double availableQty; // labst
  final String baseUnit; // meins

  StockModel({
    required this.materialID,
    required this.materialName,
    required this.plant,
    required this.storageLocation,
    required this.availableQty,
    required this.baseUnit,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      // Thử dùng chữ cái đầu viết Hoa nếu chữ thường không chạy
      materialID: json['Matnr']?.toString() ?? json['matnr']?.toString() ?? '',
      materialName:
          json['Maktx']?.toString() ?? json['maktx']?.toString() ?? '',
      plant: json['Werks']?.toString() ?? json['werks']?.toString() ?? '',
      storageLocation:
          json['Lgort']?.toString() ?? json['lgort']?.toString() ?? '',

      // Xử lý số lượng: SAP đôi khi trả về "10.000" (chuỗi) thay vì số
      availableQty: _parseSapNumber(json['Labst'] ?? json['labst']),

      baseUnit: json['Meins']?.toString() ?? json['meins']?.toString() ?? '',
    );
  }

  // Hàm bổ trợ để tránh lỗi ép kiểu số từ SAP
  static double _parseSapNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
