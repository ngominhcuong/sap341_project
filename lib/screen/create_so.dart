import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/screen/good_issue.dart';
import 'package:sap341/screen/stock.dart';
import 'package:sap341/model/Stock.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateSOScreen extends StatefulWidget {
  @override
  _CreateSOScreenState createState() => _CreateSOScreenState();
}

class _CreateSOScreenState extends State<CreateSOScreen> {
  static const String _draftKey = 'create_so_draft_v1';

  final ODataService _service = ODataService();
  bool _isSending = false;
  bool _isRestoringDraft = false;
  bool _showValidationErrors = false;
  DateTime? _lastDraftSavedAt;
  final Map<String, int> _fieldRefreshVersions = {};

  // FIX LỖI 1: Khai báo biến quản lý kho đã chọn
  Map<int, StockModel?> _selectedStocks = {};

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFF2E7D32);
  final Color backgroundLight = Color(0xFFF2F5F2);

  final TextEditingController _docTypeController = TextEditingController(
    text: 'OR',
  );
  final TextEditingController _customerController = TextEditingController(
    text: '',
  );
  final TextEditingController _salesOrgController = TextEditingController(
    text: '',
  );
  final TextEditingController _distChannelController = TextEditingController(
    text: '',
  );
  final TextEditingController _divisionController = TextEditingController(
    text: '',
  );

  List<Map<String, dynamic>> _items = [_newEmptyItem('000010')];

  static Map<String, dynamic> _newEmptyItem(String itemNo) {
    return <String, dynamic>{
      'ItemNo': itemNo,
      'MaterialID': '',
      'Quantity': '',
      'Plant': '',
      'BaseUnit': '',
    };
  }

  void _bumpFieldRefreshVersion(String itemNo) {
    _fieldRefreshVersions[itemNo] = (_fieldRefreshVersions[itemNo] ?? 0) + 1;
  }

  @override
  void initState() {
    super.initState();
    _registerFormListeners();
    _restoreDraft();
  }

  @override
  void dispose() {
    _docTypeController.removeListener(_onHeaderFieldChanged);
    _customerController.removeListener(_onHeaderFieldChanged);
    _salesOrgController.removeListener(_onHeaderFieldChanged);
    _distChannelController.removeListener(_onHeaderFieldChanged);
    _divisionController.removeListener(_onHeaderFieldChanged);

    _docTypeController.dispose();
    _customerController.dispose();
    _salesOrgController.dispose();
    _distChannelController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  void _registerFormListeners() {
    _docTypeController.addListener(_onHeaderFieldChanged);
    _customerController.addListener(_onHeaderFieldChanged);
    _salesOrgController.addListener(_onHeaderFieldChanged);
    _distChannelController.addListener(_onHeaderFieldChanged);
    _divisionController.addListener(_onHeaderFieldChanged);
  }

  void _onHeaderFieldChanged() {
    _saveDraft();
  }

  Future<void> _saveDraft() async {
    if (_isRestoringDraft) return;

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final draftItems = _items
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final draft = {
      'Doctype': _docTypeController.text,
      'Customerid': _customerController.text,
      'Salesorg': _salesOrgController.text.toUpperCase(),
      'Distchannel': _distChannelController.text.toUpperCase(),
      'Division': _divisionController.text.toUpperCase(),
      'To_Items': draftItems,
      'SavedAt': now.toIso8601String(),
    };

    await prefs.setString(_draftKey, jsonEncode(draft));
    if (!mounted) return;
    setState(() {
      _lastDraftSavedAt = now;
    });
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDraft = prefs.getString(_draftKey);

    if (rawDraft == null || rawDraft.isEmpty) return;

    try {
      final decoded = jsonDecode(rawDraft);
      if (decoded is! Map<String, dynamic>) return;

      _isRestoringDraft = true;
      if (!mounted) return;

      setState(() {
        _docTypeController.text =
            (decoded['Doctype']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Doctype'].toString()
            : 'OR';
        _customerController.text =
            (decoded['Customerid']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Customerid'].toString()
            : '';
        _salesOrgController.text =
            (decoded['Salesorg']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Salesorg'].toString().toUpperCase()
            : '';
        _distChannelController.text =
            (decoded['Distchannel']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Distchannel'].toString().toUpperCase()
            : '';
        _divisionController.text =
            (decoded['Division']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Division'].toString().toUpperCase()
            : '';

        final dynamic rawItems = decoded['To_Items'];
        if (rawItems is List) {
          final restoredItems = rawItems
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (e) => <String, dynamic>{
                  'ItemNo': e['ItemNo']?.toString() ?? '000010',
                  'MaterialID': e['MaterialID']?.toString() ?? '',
                  'Quantity': e['Quantity']?.toString() ?? '',
                  'Plant': e['Plant']?.toString() ?? '',
                  'BaseUnit': e['BaseUnit']?.toString() ?? '',
                },
              )
              .toList(growable: true);

          if (restoredItems.isNotEmpty) {
            _items = List<Map<String, dynamic>>.from(restoredItems);
            _fieldRefreshVersions
              ..clear()
              ..addEntries(
                _items.map((e) => MapEntry(e['ItemNo']?.toString() ?? '', 1)),
              );
          }
        }

        final savedAtRaw = decoded['SavedAt']?.toString();
        _lastDraftSavedAt = savedAtRaw == null
            ? null
            : DateTime.tryParse(savedAtRaw);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã khôi phục dữ liệu.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      await prefs.remove(_draftKey);
    } finally {
      _isRestoringDraft = false;
    }
  }

  Future<void> _clearDraft({bool resetForm = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);

    if (!mounted) return;

    if (!resetForm) {
      setState(() {
        _lastDraftSavedAt = null;
      });
      return;
    }

    setState(() {
      _docTypeController.text = 'OR';
      _customerController.text = '';
      _salesOrgController.text = '';
      _distChannelController.text = '';
      _divisionController.text = '';
      _items = [_newEmptyItem('000010')];
      _selectedStocks.clear();
      _fieldRefreshVersions
        ..clear()
        ..addEntries(
          _items.map((e) => MapEntry(e['ItemNo']?.toString() ?? '', 0)),
        );
      _lastDraftSavedAt = null;
      _showValidationErrors = false;
    });
  }

  String _draftSavedAtText() {
    if (_lastDraftSavedAt == null) return 'Draft: None';
    return 'Draft saved: ${DateFormat('HH:mm dd/MM/yyyy').format(_lastDraftSavedAt!)}';
  }

  void _addItem() {
    late String newItemNo;
    setState(() {
      int nextNo = (_items.length + 1) * 10;
      newItemNo = nextNo.toString().padLeft(6, '0');
      _items = [..._items, _newEmptyItem(newItemNo)];
      _fieldRefreshVersions[newItemNo] = 0;
    });
    _saveDraft();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm dòng $newItemNo'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _removeItem(int index) async {
    if (_items.length <= 1) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa dòng ${_items[index]['ItemNo']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final removedItemNo = _items[index]['ItemNo']?.toString() ?? '';
    setState(() {
      _items = List<Map<String, dynamic>>.from(_items)..removeAt(index);
      _fieldRefreshVersions.remove(removedItemNo);
    });
    _saveDraft();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa dòng $removedItemNo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  bool _isDuplicateMaterial(String materialId, int currentIndex) {
    for (int i = 0; i < _items.length; i++) {
      if (i == currentIndex) continue;
      final existing = _items[i]['MaterialID']?.toString().trim() ?? '';
      if (existing.isNotEmpty && existing == materialId.trim()) {
        return true;
      }
    }
    return false;
  }

  Future<void> _openMaterialPicker(int index) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockScreen(isPicker: true),
      ),
    );

    if (selected == null || selected is! StockModel) {
      return;
    }

    if (_isDuplicateMaterial(selected.materialID, index)) {
      _showErrorSnackBar(
        'Material ${selected.materialID} đã có trong danh sách, không thể thêm trùng.',
      );
      return;
    }

    setState(() {
      _items[index]['MaterialID'] = selected.materialID;
      _items[index]['BaseUnit'] = selected.baseUnit;
      _items[index]['Plant'] = selected.plant;
      _bumpFieldRefreshVersion(_items[index]['ItemNo']?.toString() ?? '');

      // Reset kho đã chọn của dòng hiện tại khi đổi material.
      _selectedStocks[index] = selected;
    });
    _saveDraft();
  }

  Future<void> _submitOrder() async {
    setState(() {
      _showValidationErrors = true;
    });

    if (_customerController.text.trim().isEmpty) {
      _showErrorSnackBar("Vui lòng nhập mã khách hàng");
      return;
    }
    if (_salesOrgController.text.trim().isEmpty ||
        _distChannelController.text.trim().isEmpty ||
        _divisionController.text.trim().isEmpty) {
      _showErrorSnackBar("Vui lòng nhập đầy đủ Sales Org, Channel, Division");
      return;
    }
    for (var item in _items) {
      if (item['MaterialID'].isEmpty) {
        _showErrorSnackBar("Dòng ${item['ItemNo']} chưa chọn vật tư");
        return;
      }

      final plant = item['Plant']?.toString().trim() ?? '';
      if (plant.isEmpty) {
        _showErrorSnackBar("Dòng ${item['ItemNo']} chưa nhập Plant");
        return;
      }

      final qtyRaw = item['Quantity']?.toString().trim() ?? '';
      final qty = double.tryParse(qtyRaw);
      if (qty == null || qty <= 0) {
        _showErrorSnackBar("Dòng ${item['ItemNo']} có số lượng phải lớn hơn 0");
        return;
      }
    }

    setState(() => _isSending = true);

    final createdItems = _items
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    Map<String, dynamic> soPayload = {
      "Doctype": _docTypeController.text,
      "Customerid": _customerController.text,
      "Salesorg": _salesOrgController.text.toUpperCase(),
      "Distchannel": _distChannelController.text.toUpperCase(),
      "Division": _divisionController.text.toUpperCase(),
      "To_Items": _items
          .map(
            (item) => {
              "Itemno": item['ItemNo'],
              "Materialid": item['MaterialID'],
              "Plant": item['Plant'],
              "Quantity": item['Quantity'],
            },
          )
          .toList(),
    };

    try {
      final result = await _service.createSalesOrder(soPayload);
      String orderId = result['Orderid'] ?? "N/A";
      await _clearDraft();
      _showSuccessAndNavigate(orderId, createdItems);
    } catch (e) {
      _showErrorSnackBar("Lỗi SAP: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSuccessAndNavigate(
    String orderId,
    List<Map<String, dynamic>> createdItems,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          "Sales Order $orderId đã tạo thành công!",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _goHome();
                },
                child: Text("VỀ HOME", style: TextStyle(color: primaryGreen)),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoodsIssueScreen(
                        orderId: orderId,
                        items: createdItems,
                      ),
                    ),
                  );
                },
                child: Text(
                  "TIẾP TỤC POST GI",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundLight,
        body: Column(
          children: [
            _buildElegantHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(20),
                children: [
                  _buildSectionHeader(
                    "THÔNG TIN ĐƠN HÀNG",
                    Icons.description_outlined,
                  ),
                  _buildCustomerCard(),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildSectionHeader(
                          "CHI TIẾT VẬT TƯ",
                          Icons.shopping_cart_outlined,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: accentGreen,
                          size: 20,
                        ),
                        label: Text(
                          "Thêm dòng",
                          style: TextStyle(
                            color: accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ..._items
                      .asMap()
                      .entries
                      .map((e) => _buildItemCard(e.key, e.value))
                      .toList(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildSubmitButton(),
      ),
    );
  }

  Widget _buildElegantHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 25,
        left: 10,
        right: 10,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _goHome,
              ),
              Expanded(
                child: Text(
                  "Tạo Sales Order",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.save_outlined, color: Colors.white, size: 22),
                onPressed: () async {
                  await _saveDraft();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu bản nháp.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () async {
                  await _clearDraft(resetForm: true);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa bản nháp.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Text(
              _draftSavedAtText(),
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  _docTypeController,
                  "Loại (Type)",
                  Icons.assignment_outlined,
                  hintText: 'OR',
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                flex: 4,
                child: _buildTextField(
                  _customerController,
                  "Mã Khách hàng",
                  Icons.person_search_outlined,
                  hintText: 'VD: 100001',
                  errorText:
                      _showValidationErrors &&
                          _customerController.text.trim().isEmpty
                      ? 'Bắt buộc'
                      : null,
                ),
              ),
            ],
          ),
          Divider(height: 30, color: backgroundLight),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _salesOrgController,
                  "Sales Org",
                  Icons.business_outlined,
                  hintText: 'VD: 1000',
                  errorText:
                      _showValidationErrors &&
                          _salesOrgController.text.trim().isEmpty
                      ? 'Bắt buộc'
                      : null,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _distChannelController,
                  "Channel",
                  Icons.hub_outlined,
                  hintText: 'VD: 10',
                  errorText:
                      _showValidationErrors &&
                          _distChannelController.text.trim().isEmpty
                      ? 'Bắt buộc'
                      : null,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _divisionController,
                  "Division",
                  Icons.layers_outlined,
                  hintText: 'VD: 00',
                  errorText:
                      _showValidationErrors &&
                          _divisionController.text.trim().isEmpty
                      ? 'Bắt buộc'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(top: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: primaryGreen.withOpacity(0.1),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _openMaterialPicker(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _showValidationErrors &&
                                  item['MaterialID'].toString().trim().isEmpty
                              ? Colors.red
                              : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Text(
                      item['MaterialID'].isEmpty
                          ? "Chạm để chọn vật tư..."
                          : item['MaterialID'],
                      style: TextStyle(
                        color: item['MaterialID'].isEmpty
                            ? Colors.grey
                            : Colors.black87,
                        fontWeight: item['MaterialID'].isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 120,
                child: _buildSmallInput(
                  "Số lượng",
                  (v) {
                    item['Quantity'] = v;
                    _saveDraft();
                  },
                  initialValue: item['Quantity'],
                  hintText: 'Nhập > 0',
                  errorText: _showValidationErrors
                      ? _quantityErrorText(item['Quantity']?.toString() ?? '')
                      : null,
                  fieldKey: ValueKey(
                    'qty_${item['ItemNo']}_${_fieldRefreshVersions[item['ItemNo']?.toString() ?? ''] ?? 0}',
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: _buildSmallInput(
                  "Plant",
                  (v) {
                    item['Plant'] = v;
                    _saveDraft();
                  },
                  initialValue: item['Plant'],
                  hintText: 'VD: 1000',
                  keyboardType: TextInputType.text,
                  errorText:
                      _showValidationErrors &&
                          item['Plant'].toString().trim().isEmpty
                      ? 'Bắt buộc'
                      : null,
                  fieldKey: ValueKey(
                    'plant_${item['ItemNo']}_${_fieldRefreshVersions[item['ItemNo']?.toString() ?? ''] ?? 0}',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  (item['BaseUnit']?.toString().trim().isEmpty ?? true)
                      ? '-'
                      : item['BaseUnit'].toString(),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hintText,
    String? errorText,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: (_) {
        if (_showValidationErrors) {
          setState(() {});
        }
      },
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        errorText: errorText,
        prefixIcon: Icon(icon, color: accentGreen, size: 18),
        border: UnderlineInputBorder(),
        labelStyle: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.normal,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }

  Widget _buildSmallInput(
    String label,
    Function(String) onChanged, {
    String? initialValue,
    String? hintText,
    String? errorText,
    TextInputType keyboardType = TextInputType.number,
    Key? fieldKey,
  }) {
    return TextFormField(
      key: fieldKey,
      initialValue: initialValue,
      onChanged: (v) {
        onChanged(v);
        if (_showValidationErrors) {
          setState(() {});
        }
      },
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        errorText: errorText,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }

  String? _quantityErrorText(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Bắt buộc';
    final qty = double.tryParse(value);
    if (qty == null || qty <= 0) return '> 0';
    return null;
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryGreen.withOpacity(0.5)),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryGreen.withOpacity(0.5),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _submitOrder,
        icon: _isSending
            ? SizedBox()
            : Icon(Icons.check_circle_outline, color: Colors.white),
        label: _isSending
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                "TẠO ĐƠN & TIẾP TỤC",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String m) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }
}
