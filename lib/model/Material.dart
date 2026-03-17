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
      // SAP thường trả về Matnr có nhiều số 0 ở đầu (0000000000123),
      // ta giữ nguyên để gửi lên SAP không bị lỗi, nhưng lúc hiển thị sẽ trim sau.
      materialID: json['Matnr']?.toString() ?? '',

      materialName: json['Maktx']?.toString() ?? 'No Name',

      materialType: json['Mtart']?.toString() ?? '',

      baseUnit: json['Meins']?.toString() ?? 'PC',

      // Nếu Backend không trả về Plant, hãy gán mặc định là '1000'
      // vì tạo Sales Order trong SAP bắt buộc phải có Plant ở mức Item.
      plant:
          json['Werks_d']?.toString() ??
          json['Werks']?.toString() ??
          json['WerksD']?.toString() ??
          '',
    );
  }

  // Thêm method này để dễ dàng chuyển đổi khi cần tạo Payload gửi đi
  Map<String, dynamic> toJson() {
    return {
      'Matnr': materialID,
      'Maktx': materialName,
      'Meins': baseUnit,
      'Werks': plant,
    };
  }
}
