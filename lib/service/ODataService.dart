import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sap341/model/Material.dart';
import 'package:sap341/model/Stock.dart';
import 'package:sap341/model/SalesOrder.dart';

class ODataService {
  // Thay đổi các thông số cấu hình dưới đây cho đúng với hệ thống của bạn
  final String baseUrl =
      "https://s40lp1.ucc.cit.tum.de/sap/opu/odata/sap/Z_GR5_SE1877_PRJ_SRV";
  final String username = "dev-385";
  final String password = "doducanh";

  // Biến lưu trữ CSRF Token để dùng cho POST/PUT
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

  // 1. Hàm lấy CSRF Token (Bắt buộc để POST SalesOrder hoặc PUT Stock)
  Future<void> _fetchCsrfToken() async {
    final response = await http.get(
      Uri.parse(baseUrl + "/"),
      headers: {..._authHeader, 'X-CSRF-Token': 'Fetch'},
    );

    if (response.statusCode == 200) {
      _csrfToken = response.headers['x-csrf-token'];
      _cookie = response.headers['set-cookie'];
    }
  }

  // lib/services/odata_service.dart

  Future<String> createDeepSalesOrder(SalesOrderHeader so) async {
    await _fetchCsrfToken();

    final response = await http.post(
      Uri.parse("$baseUrl/SaleOrderHeaderSet"), // Khớp với CASE trong ABAP
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        'Cookie': _cookie ?? '',
      },
      body: jsonEncode(so.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['d']['OrderID']; // ABAP gán lv_salesdocument vào orderid
    } else {
      // Backend của bạn dùng add_messages_from_bapi, nên lỗi sẽ trả về rất chi tiết ở đây
      throw Exception('Lỗi SAP: ${response.body}');
    }
  }

  // 2. GET MaterialSet (Có phân trang và lọc)
  Future<List<MaterialModel>> fetchMaterials() async {
    // Chỉ lấy danh sách, chưa lọc vì Backend ABAP hiện tại chưa bắt filter
    String url = "$baseUrl/MaterialSet?\$format=json";

    final response = await http.get(Uri.parse(url), headers: _authHeader);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['d']['results'] ?? [];
      return results.map((json) => MaterialModel.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi SAP: ${response.statusCode}');
    }
  }

  // 3. GET StockSet (Kiểm tra tồn kho realtime)
  // lib/services/odata_service.dart

  Future<List<StockModel>> fetchStocks({String? materialID}) async {
    // 1. Dùng list các tham số để nối cho chuẩn
    List<String> queryParams = ["\$format=json"];

    if (materialID != null && materialID.trim().isNotEmpty) {
      // Quan trọng: Phải bao giá trị trong dấu nháy đơn ' '
      queryParams.add("\$filter=Materialid eq '${materialID.trim()}'");
    }

    // 2. Nối các tham số bằng dấu & và bắt đầu bằng ?
    String fullUrl = "$baseUrl/StockSet?" + queryParams.join("&");

    print("DEBUG URL GỌI SAP: $fullUrl");

    try {
      final response = await http.get(Uri.parse(fullUrl), headers: _authHeader);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['d']['results'] ?? [];
        return results.map((json) => StockModel.fromJson(json)).toList();
      } else {
        print("Lỗi SAP ${response.statusCode}: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      return [];
    }
  }

  // 4. POST SalesOrderSet (Tạo đơn hàng)
  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    // Bước A: Lấy token mới trước khi tạo
    await _fetchCsrfToken();

    final response = await http.post(
      Uri.parse("$baseUrl/SalesOrderSet"),
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        'Cookie': _cookie ?? '',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['d']; // Trả về thông tin SalesOrder vừa tạo (gồm VBELN)
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error']['message']['value'] ?? 'Lỗi tạo Sales Order',
      );
    }
  }

  // 5. PUT StockUpdateSet (Cập nhật tồn kho sau khi bán)
  Future<bool> updateStock(
    String matnr,
    String werks,
    String lgort,
    double newQty,
  ) async {
    await _fetchCsrfToken();

    // Cấu trúc URL OData PUT thường là: EntitySet(Key1='val', Key2='val')
    String url =
        "$baseUrl/StockUpdateSet(MaterialID='$matnr',Plant='$werks',StorageLocation='$lgort')";

    final response = await http.put(
      Uri.parse(url),
      headers: {
        ..._authHeader,
        'X-CSRF-Token': _csrfToken ?? '',
        'Cookie': _cookie ?? '',
      },
      body: jsonEncode({
        "MaterialID": matnr,
        "Plant": werks,
        "StorageLocation": lgort,
        "AvailableQty": newQty.toString(),
      }),
    );

    return response.statusCode == 204 || response.statusCode == 200;
  }
}
