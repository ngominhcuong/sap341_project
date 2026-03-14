class StockModel {
  final String materialID; // materialid
  final String plant; // plant
  final String storageLocation; // storageloc
  final double availableQty; // availablestock
  final String baseUnit; // baseunit

  StockModel({
    required this.materialID,
    required this.plant,
    required this.storageLocation,
    required this.availableQty,
    required this.baseUnit,
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
}
