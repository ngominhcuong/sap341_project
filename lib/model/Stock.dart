class StockModel {
  final String materialID;
  final String storageLocation;
  final String plant;
  final String baseUnit;

  // XÓA 'final' ở dòng này để có thể thay đổi giá trị
  double availableQty;

  StockModel({
    required this.materialID,
    required this.storageLocation,
    required this.plant,
    required this.baseUnit,
    required this.availableQty, // Đảm bảo constructor vẫn nhận giá trị này
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      materialID: json['Materialid']?.toString() ?? '',
      plant: json['Plant']?.toString() ?? '',
      storageLocation: json['Storageloc']?.toString() ?? '',
      availableQty:
          double.tryParse(json['Availablestock']?.toString() ?? '0') ?? 0.0,
      baseUnit: json['Baseunit']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockModel &&
          runtimeType == other.runtimeType &&
          storageLocation == other.storageLocation &&
          materialID == other.materialID;

  @override
  int get hashCode => storageLocation.hashCode ^ materialID.hashCode;
}
