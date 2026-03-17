import 'package:flutter/material.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Material.dart';
import 'package:sap341/screen/material_list.dart';
import 'package:sap341/screen/good_issue.dart';
import 'package:sap341/model/Stock.dart';

class CreateSOScreen extends StatefulWidget {
  @override
  _CreateSOScreenState createState() => _CreateSOScreenState();
}

class _CreateSOScreenState extends State<CreateSOScreen> {
  final ODataService _service = ODataService();
  bool _isSending = false;

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
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
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
                    _buildSectionHeader(
                      "CHI TIẾT VẬT TƯ",
                      Icons.shopping_cart_outlined,
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

  // --- TRẢ LẠI TOÀN BỘ UI COMPONENTS GỐC CỦA BẠN ---

  Widget _buildElegantHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 25,
        left: 10,
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
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Tạo Sales Order",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
          Row(
            children: [
              Expanded(
                child: _buildSmallInput(
                  "Số lượng",
                  (v) => item['Quantity'] = v,
                  initialValue: item['Quantity'],
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildSmallInput(
                  "Plant",
                  (v) => item['Plant'] = v,
                  initialValue: item['Plant'],
                ),
              ),
              SizedBox(width: 20),
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
