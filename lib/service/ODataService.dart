import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sap341/model/Material.dart';
import 'package:sap341/model/Stock.dart';

class ODataService {
  final String baseUrl =
      "https://s40lp1.ucc.cit.tum.de/sap/opu/odata/sap/Z_GR5_SE1877_PRJ_SRV";
  final String username = "dev-382";
  final String password = "ngominhcuong"; // Thay bằng password của bạn

  String? _csrfToken;
  String? _cookie;

  // Header xác thực cơ bản dùng cho các lệnh GET
  Map<String, String> get _authHeader {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'Accept-Language': 'en',
    };
  }

  // --- HÀM LẤY TOKEN & COOKIE (Cần thiết cho POST, PUT, DELETE) ---
  Future<void> _fetchCsrfToken() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/"),
        headers: {..._authHeader, 'X-CSRF-Token': 'Fetch'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _csrfToken = response.headers['x-csrf-token'];
        _cookie = response.headers['set-cookie'];
        print("DEBUG: Fetch Token & Cookie thành công");
      }
    } catch (e) {
      print("DEBUG: Lỗi fetch token: $e");
    }
  }

  // --- 1. TẠO SALES ORDER (DEEP INSERT) ---
  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    await _fetchCsrfToken();

    final response = await http.post(
      Uri.parse('$baseUrl/SalesOrderHeaderSet'),
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        if (_cookie != null) 'Cookie': _cookie!,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['d'];
    } else {
      throw Exception("Lỗi tạo SO: ${response.body}");
    }
  }

  // --- 2. LẤY DANH SÁCH VẬT TƯ ---
  Future<List<MaterialModel>> fetchMaterials({String? plant}) async {
    String url = "$baseUrl/MaterialSet?\$format=json";

    // Thêm filter nếu có chọn nhà máy
    if (plant != null && plant.isNotEmpty && plant != 'Tất cả') {
      url += "&\$filter=WERKS_D eq '$plant'";
    }

    try {
      final response = await http.get(Uri.parse(url), headers: _authHeader);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['d']?['results'] ?? [];
        return results.map((json) => MaterialModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi lấy vật tư: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching materials: $e");
      return [];
    }
  }

  // --- 3. LẤY TỒN KHO (Hỗ trợ cả lấy TOÀN BỘ hoặc LỌC) ---
  // Để lấy toàn bộ, chỉ cần gọi: fetchStocks()
  // Để lọc vật tư, gọi: fetchStocks(materialID: 'MATE_01')
  Future<List<StockModel>> fetchStocks({
    String? materialID,
    String? plant,
  }) async {
    List<String> filters = [];

    // Lọc theo MaterialID (nếu có)
    if (materialID != null && materialID.trim().isNotEmpty) {
      String formattedID = materialID.trim();
      // Nếu là số thì thêm số 0 ở đầu cho chuẩn SAP (18 ký tự)
      if (RegExp(r'^[0-9]+$').hasMatch(formattedID)) {
        formattedID = formattedID.padLeft(18, '0');
      }
      filters.add("Materialid eq '$formattedID'");
    }

    // Lọc theo Plant (nếu có)
    if (plant != null && plant.isNotEmpty && plant != 'Tất cả') {
      filters.add("Plant eq '$plant'");
    }

    // Xây dựng Query String
    String filterQuery = "";
    if (filters.isNotEmpty) {
      filterQuery = "&\$filter=" + filters.join(" and ");
    }

    final String url = "$baseUrl/StockSet?\$format=json$filterQuery";

    try {
      print("DEBUG URL Stock: $url");
      final response = await http.get(Uri.parse(url), headers: _authHeader);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['d']?['results'] ?? [];
        return results.map((json) => StockModel.fromJson(json)).toList();
      } else {
        print("SAP Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Connection Error: $e");
      return [];
    }
  }

  // --- 4. CẬP NHẬT TỒN KHO ---
  Future<void> updateStock(Map<String, dynamic> data) async {
    await _fetchCsrfToken();

    // Key OData: Materialid, Plant, Storageloc
    final String matId = data['Materialid'];
    final String plant = data['Plant'];
    final String sloc = data['Storageloc'];

    // Encode URL để tránh lỗi ký tự đặc biệt trong Key
    final String resourcePath =
        "StockUpdateSet(Materialid='$matId',Plant='$plant',Storageloc='$sloc')";
    final url = Uri.parse("$baseUrl/$resourcePath");

    final response = await http.put(
      url,
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        if (_cookie != null) 'Cookie': _cookie!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        "Lỗi cập nhật SAP (${response.statusCode}): ${response.body}",
      );
    }
    print("DEBUG: Cập nhật tồn kho thành công!");
  }
}
