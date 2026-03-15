import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sap341/model/Material.dart';
import 'package:sap341/model/Stock.dart';

class ODataService {
  final String baseUrl =
      "https://s40lp1.ucc.cit.tum.de/sap/opu/odata/sap/Z_GR5_SE1877_PRJ_SRV";
  final String username = "dev-";
  final String password = "";

  // Bộ nhớ đệm cho bảo mật
  String? _csrfToken;
  String? _cookie;

  // Header cơ bản kèm Authentication
  Map<String, String> get _authHeader {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': basicAuth,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  // --- HÀM QUAN TRỌNG: Lấy Token và giữ Session ---
  Future<void> _fetchCsrfToken() async {
    // Gọi một yêu cầu GET nhẹ nhàng để lấy Token
    final response = await http.get(
      Uri.parse("$baseUrl/"),
      headers: {..._authHeader, 'X-CSRF-Token': 'Fetch'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _csrfToken = response.headers['x-csrf-token'];

      // Lấy toàn bộ Cookie trả về (SAP có thể trả về nhiều dòng Set-Cookie)
      _cookie = response.headers['set-cookie'];

      print("DEBUG: Đã lấy Token thành công: $_csrfToken");
    } else {
      print("DEBUG: Không lấy được Token. Mã lỗi: ${response.statusCode}");
    }
  }

  // --- 1. TẠO SALES ORDER (DEEP INSERT) ---
  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    // Luôn fetch token mới trước khi POST để đảm bảo session còn sống
    await _fetchCsrfToken();

    final response = await http.post(
      Uri.parse('$baseUrl/SalesOrderHeaderSet'),
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        'Cookie': _cookie ?? '', // Bắt buộc phải có Cookie đi kèm Token
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      // Thành công: SAP trả về dữ liệu đơn hàng vừa tạo
      return jsonDecode(response.body)['d'];
    } else {
      // Thất bại: Trả về chi tiết lỗi từ backend ABAP (BAPI Return)
      print("LỖI TẠO ĐƠN: ${response.body}");
      throw Exception('Lỗi SAP (${response.statusCode}): ${response.body}');
    }
  }

  // --- 2. LẤY DANH SÁCH VẬT TƯ ---
  Future<List<MaterialModel>> fetchMaterials() async {
    String url = "$baseUrl/MaterialSet?\$format=json";

    final response = await http.get(Uri.parse(url), headers: _authHeader);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['d']['results'] ?? [];
      return results.map((json) => MaterialModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi lấy vật tư: ${response.statusCode}');
    }
  }

  // --- 3. KIỂM TRA TỒN KHO ---
  Future<List<StockModel>> fetchStocks({String? materialID}) async {
    List<String> queryParams = ["\$format=json"];

    if (materialID != null && materialID.trim().isNotEmpty) {
      queryParams.add("\$filter=Materialid eq '${materialID.trim()}'");
    }

    String fullUrl = "$baseUrl/StockSet?" + queryParams.join("&");

    try {
      final response = await http.get(Uri.parse(fullUrl), headers: _authHeader);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['d']['results'] ?? [];
        return results.map((json) => StockModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // --- 4. CẬP NHẬT TỒN KHO (PUT) ---
  Future<bool> updateStock(
    String matnr,
    String werks,
    String lgort,
    double qty,
  ) async {
    await _fetchCsrfToken();

    // URL OData cho Update (PUT) yêu cầu chỉ định Key cụ thể
    String url =
        "$baseUrl/StockUpdateSet(Materialid='$matnr',Plant='$werks',Storageloc='$lgort')";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        'Cookie': _cookie ?? '',
      },
      body: jsonEncode({
        "Materialid": matnr,
        "Plant": werks,
        "Storageloc": lgort,
        "Quantity": qty.toString(),
      }),
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }
}
