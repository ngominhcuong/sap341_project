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
      // Dựa trên XML của bạn: <d:Matnr>, <d:Maktx>, <d:Mtart>, <d:Meins>, <d:Werks>
      // Lưu ý: OData JSON sẽ giữ nguyên chữ hoa chữ cái đầu
      materialID: json['Matnr']?.toString() ?? '',
      materialName: json['Maktx']?.toString() ?? '',
      materialType: json['Mtart']?.toString() ?? '',
      baseUnit: json['Meins']?.toString() ?? '',
      plant: json['Werks']?.toString() ?? '',
    );
  }
}
