// Material Model [cite: 31]
class MaterialModel {
  final String materialID; // matnr
  final String materialName; // maktx
  final String materialType; // mtart
  final String baseUnit; // meins
  final String plant; // werks

  MaterialModel({
    required this.materialID,
    required this.materialName,
    required this.materialType,
    required this.baseUnit,
    required this.plant,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      materialID: json['MaterialID'] ?? '',
      materialName: json['MaterialName'] ?? '',
      materialType: json['MaterialType'] ?? '',
      baseUnit: json['BaseUnit'] ?? '',
      plant: json['Plant'] ?? '',
    );
  }
}
