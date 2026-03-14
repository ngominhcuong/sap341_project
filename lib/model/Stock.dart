class StockModel {
  final String materialID; // MATNR
  final String materialName; // MAKTX
  final String plant; // WERKS
  final String storageLocation; // LGORT
  final double availableQty; // LABST (Số lượng tồn)
  final String baseUnit; // MEINS

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
      materialID: json['MaterialID'] ?? '',
      materialName: json['MaterialName'] ?? '',
      plant: json['Plant'] ?? '',
      storageLocation: json['StorageLocation'] ?? '',
      // SAP thường trả về số lượng dạng String/Decimal, cần ép kiểu double
      availableQty: double.tryParse(json['AvailableQty'].toString()) ?? 0.0,
      baseUnit: json['BaseUnit'] ?? '',
    );
  }
}
