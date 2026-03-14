// lib/model/Material.dart

class MaterialModel {
  final String materialID;
  final String materialName;
  final String materialType;
  final String baseUnit;
  final String plant;

  MaterialModel({
    required this.materialID,
    required this.materialName,
    required this.materialType,
    required this.baseUnit,
    required this.plant,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      // Key khớp với SELECT a~matnr
      materialID: json['Matnr']?.toString() ?? '',
      // Key khớp với SELECT b~maktx
      materialName: json['Maktx']?.toString() ?? '',
      // Key khớp với SELECT a~mtart
      materialType: json['Mtart']?.toString() ?? '',
      // Key khớp với SELECT a~meins
      baseUnit: json['Meins']?.toString() ?? '',
      // Gán mặc định vì bạn đã bỏ Plant ở Backend
      plant: '',
    );
  }
}
