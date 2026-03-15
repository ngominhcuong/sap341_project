import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sap341/model/Material.dart';
import 'package:sap341/model/Stock.dart';

class ODataService {
  final String baseUrl =
      "https://s40lp1.ucc.cit.tum.de/sap/opu/odata/sap/Z_GR5_SE1877_PRJ_SRV";
  final String username = "dev-385";
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
  // lib/service/ODataService.dart

  // lib/service/ODataService.dart

  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    // Bước 1: Luôn Fetch token mới nhất ngay trước khi POST
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
      final responseData = jsonDecode(response.body)['d'];

      // Bước 2: Chỉ trừ kho khi tạo đơn thành công
      if (payload.containsKey('To_Items')) {
        List items = payload['To_Items'];
        for (var item in items) {
          await updateStock(
            matnr: item['Materialid'] ?? '',
            werks: item['Plant'] ?? '',
            lgort: item['Storageloc'] ?? '',
            qty: item['Quantity'] ?? '0',
            // Sử dụng trường tạm từ UI gửi qua để phục vụ updateStock
            meins: item['_InternalBaseUnit'] ?? 'PC',
          );
        }
      }
      return responseData;
    } else {
      // Trả về lỗi chi tiết từ SAP (như hình 2 bạn gửi)
      throw Exception(response.body);
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
  // lib/services/odata_service.dart

  // --- 4. CẬP NHẬT TỒN KHO (Kích hoạt BAPI_GOODSMVT_CREATE ở Backend) ---
  Future<bool> updateStock({
    required String matnr,
    required String werks,
    required String lgort,
    required String qty,
    required String meins,
  }) async {
    await _fetchCsrfToken();

    // Lưu ý: Đảm bảo Materialid, Plant, Storageloc viết HOA/thường đúng như trong SEGW
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
        "Quantity": qty, // Đảm bảo Backend nhận được chuỗi số (Vd: "10.000")
        "Movetype": "551",
        "Baseunit": meins, // Backend của bạn dùng ls_request-baseunit
      }),
    );

    // QUAN TRỌNG: Kiểm tra xem SAP trả về cái gì
    print("DEBUG STATUS: ${response.statusCode}");
    print("DEBUG BODY: ${response.body}");

    if (response.statusCode != 204 && response.statusCode != 200) {
      // Nếu lỗi, in ra để debug
      print("Lỗi trừ kho từ SAP: ${response.body}");
    }

    return response.statusCode == 204 || response.statusCode == 200;
  }
}
