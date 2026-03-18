import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Material.dart';
import 'package:sap341/screen/material_list.dart';
import 'package:sap341/screen/good_issue.dart';
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
  DateTime? _lastDraftSavedAt;

  // FIX LỖI 1: Khai báo biến quản lý kho đã chọn
  Map<int, StockModel?> _selectedStocks = {};

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFF2E7D32);
  final Color backgroundLight = Color(0xFFF2F5F2);

  final TextEditingController _docTypeController = TextEditingController(
    text: 'OR',
  );
  final TextEditingController _customerController = TextEditingController(
    text: '100001',
  );
  final TextEditingController _salesOrgController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _distChannelController = TextEditingController(
    text: '10',
  );
  final TextEditingController _divisionController = TextEditingController(
    text: '00',
  );

  List<Map<String, dynamic>> _items = [
    {
      'ItemNo': '000010',
      'MaterialID': '',
      'Quantity': '1',
      'Plant': '1000',
      'BaseUnit': 'PC',
    },
  ];

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
    final draft = {
      'Doctype': _docTypeController.text,
      'Customerid': _customerController.text,
      'Salesorg': _salesOrgController.text,
      'Distchannel': _distChannelController.text,
      'Division': _divisionController.text,
      'To_Items': _items,
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
            : '100001';
        _salesOrgController.text =
            (decoded['Salesorg']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Salesorg'].toString()
            : '1000';
        _distChannelController.text =
            (decoded['Distchannel']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Distchannel'].toString()
            : '10';
        _divisionController.text =
            (decoded['Division']?.toString().trim().isNotEmpty ?? false)
            ? decoded['Division'].toString()
            : '00';

        final dynamic rawItems = decoded['To_Items'];
        if (rawItems is List) {
          final restoredItems = rawItems
              .whereType<Map>()
              .map(
                (e) => {
                  'ItemNo': e['ItemNo']?.toString() ?? '000010',
                  'MaterialID': e['MaterialID']?.toString() ?? '',
                  'Quantity': e['Quantity']?.toString() ?? '1',
                  'Plant': e['Plant']?.toString() ?? '1000',
                  'BaseUnit': e['BaseUnit']?.toString() ?? 'PC',
                },
              )
              .toList();

          if (restoredItems.isNotEmpty) {
            _items = restoredItems;
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
      _customerController.text = '100001';
      _salesOrgController.text = '1000';
      _distChannelController.text = '10';
      _divisionController.text = '00';
      _items = [
        {
          'ItemNo': '000010',
          'MaterialID': '',
          'Quantity': '1',
          'Plant': '1000',
          'BaseUnit': 'PC',
        },
      ];
      _selectedStocks.clear();
      _lastDraftSavedAt = null;
    });
  }

  String _draftSavedAtText() {
    if (_lastDraftSavedAt == null) return 'Draft: None';
    return 'Draft saved: ${DateFormat('HH:mm dd/MM/yyyy').format(_lastDraftSavedAt!)}';
  }

  void _addItem() {
    setState(() {
      int nextNo = (_items.length + 1) * 10;
      _items.add({
        'ItemNo': nextNo.toString().padLeft(6, '0'),
        'MaterialID': '',
        'Quantity': '1',
        'Plant': '1000',
        'BaseUnit': 'PC',
      });
    });
    _saveDraft();
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
      _saveDraft();
    }
  }

  Future<void> _openMaterialPicker(int index) async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialListScreen(isPicker: true),
      ),
    );

    if (selected != null && selected is MaterialModel) {
      setState(() {
        _items[index]['MaterialID'] = selected.materialID;
        _items[index]['BaseUnit'] = selected.baseUnit;

        // FIX LỖI 2: Reset kho dòng này khi đổi vật tư
        _selectedStocks[index] = null;
      });
      _saveDraft();
    }
  }

  Future<void> _submitOrder() async {
    if (_customerController.text.isEmpty) {
      _showErrorSnackBar("Vui lòng nhập mã khách hàng");
      return;
    }
    for (var item in _items) {
      if (item['MaterialID'].isEmpty) {
        _showErrorSnackBar("Dòng ${item['ItemNo']} chưa chọn vật tư");
        return;
      }
    }

    setState(() => _isSending = true);

    Map<String, dynamic> soPayload = {
      "Doctype": _docTypeController.text,
      "Customerid": _customerController.text,
      "Salesorg": _salesOrgController.text,
      "Distchannel": _distChannelController.text,
      "Division": _divisionController.text,
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
      _showSuccessAndNavigate(orderId);
    } catch (e) {
      _showErrorSnackBar("Lỗi SAP: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSuccessAndNavigate(String orderId) {
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
          Center(
            child: ElevatedButton(
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
                    builder: (context) =>
                        GoodsIssueScreen(orderId: orderId, items: _items),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  "XÁC NHẬN XUẤT KHO (GI)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: () => Navigator.pop(context),
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
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                flex: 4,
                child: _buildTextField(
                  _customerController,
                  "Mã Khách hàng",
                  Icons.person_search_outlined,
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
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _distChannelController,
                  "Channel",
                  Icons.hub_outlined,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _divisionController,
                  "Division",
                  Icons.layers_outlined,
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
                        bottom: BorderSide(color: Colors.grey[200]!),
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
                child: _buildSmallInput("Số lượng", (v) {
                  item['Quantity'] = v;
                  _saveDraft();
                }, initialValue: item['Quantity']),
              ),
              SizedBox(
                width: 120,
                child: _buildSmallInput("Plant", (v) {
                  item['Plant'] = v;
                  _saveDraft();
                }, initialValue: item['Plant']),
              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  item['BaseUnit'] ?? 'PC',
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
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentGreen, size: 18),
        border: InputBorder.none,
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
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
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
