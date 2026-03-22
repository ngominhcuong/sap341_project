import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sap341/model/Material.dart';
import 'package:sap341/model/Stock.dart';

class ODataService {
  final String baseUrl =
      dotenv.env['SAP_BASE_URL'] ??
      "https://s40lp1.ucc.cit.tum.de/sap/opu/odata/sap/Z_GR5_SE1877_PRJ_SRV";
  final String username = dotenv.env['SAP_USERNAME'] ?? '';
  final String password = dotenv.env['SAP_PASSWORD'] ?? '';

  // cấu hình theo SEGW cho luồng Goods Issue deep insert
  static const String goodsIssueEntitySet = 'StockUpdateSet';
  static const String goodsIssueItemsNavProperty = 'To_Items';
  static const String salesOrderEntitySet = 'SalesOrderHeaderSet';
  static const String salesOrderItemsNavProperty = 'To_Items';

  String? _csrfToken;
  final Map<String, String> _sessionCookies = <String, String>{};

  // header xác thực cơ bản dùng cho các lệnh GET
  Map<String, String> get _authHeader {
    if (username.isEmpty || password.isEmpty) {
      throw StateError(
        'Missing SAP credentials in .env. Please set SAP_USERNAME and SAP_PASSWORD.',
      );
    }

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

  String _buildCookieHeader() {
    return _sessionCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _extractCookies(String? rawSetCookie) {
    if (rawSetCookie == null || rawSetCookie.isEmpty) return;

    final cookieParts = rawSetCookie.split(RegExp(r',(?=\s*[^;,\s]+=)'));
    for (final part in cookieParts) {
      final firstSegment = part.split(';').first.trim();
      final sepIndex = firstSegment.indexOf('=');
      if (sepIndex <= 0) continue;

      final cookieName = firstSegment.substring(0, sepIndex).trim();
      final cookieValue = firstSegment.substring(sepIndex + 1).trim();

      if (cookieName.isEmpty || cookieValue.isEmpty) continue;
      if (_isCookieAttribute(cookieName)) continue;
      _sessionCookies[cookieName] = cookieValue;
    }
  }

  bool _isCookieAttribute(String name) {
    const attrs = {
      'path',
      'expires',
      'max-age',
      'domain',
      'secure',
      'httponly',
      'samesite',
      'priority',
    };
    return attrs.contains(name.toLowerCase());
  }

  Future<void> _fetchCsrfFromUrl(
    String url, {
    Map<String, String>? extraHeaders,
  }) async {
    final headers = {..._authHeader, 'X-CSRF-Token': 'Fetch'};
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      return;
    }

    final token = response.headers['x-csrf-token'];
    if (token != null && token.trim().isNotEmpty) {
      _csrfToken = token.trim();
    }
    _extractCookies(response.headers['set-cookie']);
  }

  // hàm lấy token và cookie (cần thiết cho POST, PUT, DELETE)
  Future<void> _fetchCsrfToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _csrfToken = null;
      _sessionCookies.clear();
    }

    final csrfProbes = <Map<String, dynamic>>[
      {
        'url': '$baseUrl/MaterialSet?\$format=json&\$top=1',
        'headers': <String, String>{},
      },
      {
        'url': '$baseUrl/StockSet?\$format=json&\$top=1',
        'headers': <String, String>{},
      },
      {
        'url': '$baseUrl/\$metadata',
        'headers': <String, String>{'Accept': 'application/xml'},
      },
      {'url': '$baseUrl/?\$format=json', 'headers': <String, String>{}},
    ];

    for (final probe in csrfProbes) {
      final url = probe['url'] as String;
      final headers = probe['headers'] as Map<String, String>;
      await _fetchCsrfFromUrl(url, extraHeaders: headers);
      final hasToken = _csrfToken != null && _csrfToken!.isNotEmpty;
      final hasCookies = _sessionCookies.isNotEmpty;
      if (hasToken && hasCookies) {
        break;
      }
    }

    if (_csrfToken == null || _csrfToken!.isEmpty) {
      throw Exception('Không nhận được X-CSRF-Token từ SAP Gateway.');
    }
  }

  Future<Map<String, String>> _csrfHeaders({bool forceRefresh = false}) async {
    final hasToken = _csrfToken != null && _csrfToken!.isNotEmpty;
    if (forceRefresh || !hasToken) {
      await _fetchCsrfToken(forceRefresh: forceRefresh);
    }

    final headers = <String, String>{'X-CSRF-Token': _csrfToken!};
    if (_sessionCookies.isNotEmpty) {
      headers['Cookie'] = _buildCookieHeader();
    }
    return headers;
  }

  bool _shouldRetryForCsrf(http.Response response) {
    final body = response.body.toLowerCase();
    if (response.statusCode == 403) return true;
    return body.contains('csrf') || body.contains('token validation failed');
  }

  Future<http.Response> _postWithCsrfRetry(Uri uri, String body) async {
    final firstHeaders = {..._authHeader, ...await _csrfHeaders()};
    var response = await http.post(uri, headers: firstHeaders, body: body);
    _extractCookies(response.headers['set-cookie']);

    if (_shouldRetryForCsrf(response)) {
      final refreshedHeaders = {
        ..._authHeader,
        ...await _csrfHeaders(forceRefresh: true),
      };
      response = await http.post(uri, headers: refreshedHeaders, body: body);
      _extractCookies(response.headers['set-cookie']);
    }

    return response;
  }

  Future<http.Response> _putWithCsrfRetry(Uri uri, String body) async {
    final firstHeaders = {..._authHeader, ...await _csrfHeaders()};
    var response = await http.put(uri, headers: firstHeaders, body: body);
    _extractCookies(response.headers['set-cookie']);

    if (_shouldRetryForCsrf(response)) {
      final refreshedHeaders = {
        ..._authHeader,
        ...await _csrfHeaders(forceRefresh: true),
      };
      response = await http.put(uri, headers: refreshedHeaders, body: body);
      _extractCookies(response.headers['set-cookie']);
    }

    return response;
  }

  String _extractODataErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return '';
      }

      final error = decoded['error'];
      if (error is! Map<String, dynamic>) {
        return '';
      }

      String message = '';
      final rawMessage = error['message'];
      if (rawMessage is Map<String, dynamic>) {
        final value = rawMessage['value'];
        if (value is String) {
          message = value.trim();
        }
      } else if (rawMessage is String) {
        message = rawMessage.trim();
      }

      final Set<String> detailMessages = <String>{};
      final innerError = error['innererror'];
      if (innerError is Map<String, dynamic>) {
        final details = innerError['errordetails'];
        if (details is List) {
          for (final detail in details) {
            if (detail is Map<String, dynamic>) {
              final detailMessage = detail['message'];
              if (detailMessage is String && detailMessage.trim().isNotEmpty) {
                detailMessages.add(detailMessage.trim());
              }
            }
          }
        }
      }

      if (detailMessages.isNotEmpty) {
        if (message.isNotEmpty && !detailMessages.contains(message)) {
          return '$message; ${detailMessages.join('; ')}';
        }
        return detailMessages.join('; ');
      }

      return message;
    } catch (_) {
      return '';
    }
  }

  String _buildHttpErrorMessage(String action, http.Response response) {
    final parsed = _extractODataErrorMessage(response.body);
    if (parsed.isNotEmpty) {
      return '$action (${response.statusCode}): $parsed';
    }

    final compactBody = response.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compactBody.isEmpty) {
      return '$action (${response.statusCode})';
    }

    final preview = compactBody.length > 300
        ? '${compactBody.substring(0, 300)}...'
        : compactBody;
    return '$action (${response.statusCode}): $preview';
  }

  static String cleanErrorText(Object error) {
    String text = error.toString().trim();
    const prefixes = <String>['Exception:', 'Bad state:', 'Error:'];

    bool changed = true;
    while (changed) {
      changed = false;
      for (final prefix in prefixes) {
        if (text.startsWith(prefix)) {
          text = text.substring(prefix.length).trim();
          changed = true;
        }
      }
    }

    return text;
  }

  // --- tạo Sales Order (deep insert) ---
  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    final response = await _postWithCsrfRetry(
      Uri.parse('$baseUrl/SalesOrderHeaderSet'),
      jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['d'];
    } else {
      throw Exception(
        _buildHttpErrorMessage('Không thể tạo Sales Order', response),
      );
    }
  }

  // --- xem Sales Order (expanded entityset) ---
  Future<List<Map<String, dynamic>>> fetchSalesOrders({int top = 50}) async {
    final String query =
        '$baseUrl/$salesOrderEntitySet?\$format=json&\$expand=$salesOrderItemsNavProperty&\$top=$top';

    final response = await http.get(Uri.parse(query), headers: _authHeader);

    if (response.statusCode != 200) {
      throw Exception(
        _buildHttpErrorMessage('Không thể tải danh sách Sales Order', response),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> results = data['d']?['results'] ?? <dynamic>[];

    return results
        .whereType<Map<String, dynamic>>()
        .map(_normalizeSalesOrderHeader)
        .toList();
  }

  Map<String, dynamic> _normalizeSalesOrderHeader(Map<String, dynamic> raw) {
    final Map<String, dynamic> header = Map<String, dynamic>.from(raw);
    final dynamic itemsContainer =
        header[salesOrderItemsNavProperty] ??
        header['To_Items'] ??
        header['to_Items'] ??
        header['TO_ITEMS'];

    List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

    if (itemsContainer is Map<String, dynamic>) {
      final List<dynamic> rawItems = itemsContainer['results'] ?? <dynamic>[];
      items = rawItems
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (itemsContainer is List) {
      items = itemsContainer
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    header[salesOrderItemsNavProperty] = items;
    return header;
  }

  // --- lấy danh sách vật tư ---
  Future<List<MaterialModel>> fetchMaterials({String? plant}) async {
    String url = "$baseUrl/MaterialSet?\$format=json";

    // thêm filter nếu có chọn nhà máy
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

  // --- lấy tồn kho ---
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

  // --- cập nhật tồn kho ---
  // deep insert Goods Issue theo Entity Set header trong SEGW (ví dụ: StockUpdateSet)
  Map<String, dynamic> buildGoodsIssuePayload({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) {
    return {'Orderid': orderId, goodsIssueItemsNavProperty: items};
  }

  Future<Map<String, dynamic>> createGoodsIssue(
    Map<String, dynamic> payload,
  ) async {
    final response = await _postWithCsrfRetry(
      Uri.parse('$baseUrl/$goodsIssueEntitySet'),
      jsonEncode(payload),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      return body['d'] as Map<String, dynamic>? ?? <String, dynamic>{};
    }

    throw Exception(_buildHttpErrorMessage('Không thể post Goods Issue', response));
  }

  Future<void> updateStock(Map<String, dynamic> data) async {
    final String matId = data['Materialid'];
    final String plant = data['Plant'];
    final String sloc = data['Storageloc'];
    final String resourcePath =
        "StockUpdateSet(Materialid='$matId',Plant='$plant',Storageloc='$sloc')";
    final url = Uri.parse("$baseUrl/$resourcePath");

    final response = await _putWithCsrfRetry(url, jsonEncode(data));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(_buildHttpErrorMessage('Không thể cập nhật tồn kho SAP', response));
    }
    print("DEBUG: Cập nhật tồn kho thành công!");
  }
}
