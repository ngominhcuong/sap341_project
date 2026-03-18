import 'package:flutter/material.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Stock.dart';

class GoodsIssueScreen extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> items;

  const GoodsIssueScreen({Key? key, required this.orderId, required this.items})
    : super(key: key);

  @override
  _GoodsIssueScreenState createState() => _GoodsIssueScreenState();
}

class _GoodsIssueScreenState extends State<GoodsIssueScreen> {
  final ODataService _service = ODataService();
  bool _isProcessing = false;

  // Người dùng chỉ nhập thêm Movetype + Storageloc cho từng item
  final Map<int, TextEditingController> _moveTypeControllers = {};
  final Map<int, String?> _selectedStorageLocs = {};

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.items.length; i++) {
      _moveTypeControllers[i] = TextEditingController(text: '601');
    }
  }

  @override
  void dispose() {
    for (final controller in _moveTypeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F5F2),
      appBar: AppBar(
        title: Text(
          "Xác nhận Xuất kho",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        iconTheme: IconThemeData(
          color: Colors.white,
        ), // Đảm bảo nút back màu trắng
      ),
      body: Column(
        children: [
          _buildOrderSummary(),
          Expanded(child: _buildItemList()),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(20),
      color: primaryGreen,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ĐƠN HÀNG: #${widget.orderId}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Điền Movetype và chọn Storageloc cho từng vật tư",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.builder(
      padding: EdgeInsets.all(15),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];

        return Card(
          margin: EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: CircleAvatar(
              backgroundColor: accentGreen,
              child: Icon(Icons.inventory_2, color: Colors.white, size: 20),
            ),
            title: Text(
              item['MaterialID'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Số lượng: ${item['Quantity']} ${item['BaseUnit']}"),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                child: Column(
                  children: [
                    Divider(),
                    _buildMoveTypeField(index),
                    SizedBox(height: 10),
                    _buildStorageLocPicker(
                      index,
                      item['MaterialID']?.toString() ?? '',
                      item['Plant']?.toString() ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoveTypeField(int index) {
    return TextField(
      controller: _moveTypeControllers[index],
      decoration: InputDecoration(
        labelText: "Movement Type",
        hintText: "Ví dụ: 601, 201, 551",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStorageLocPicker(int index, String matId, String plant) {
    return FutureBuilder<List<StockModel>>(
      key: ValueKey('picker_${matId}_$index'),
      future: _service.fetchStocks(materialID: matId, plant: plant),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LinearProgressIndicator();
        }

        List<StockModel> allStocks = snapshot.data ?? [];
        List<StockModel> filteredStocks = allStocks
            .where((s) => s.materialID == matId)
            .toList();

        if (filteredStocks.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Không lấy được danh sách kho. Bạn có thể nhập Storageloc thủ công.",
                  style: TextStyle(color: Colors.orange[800], fontSize: 12),
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: "Storageloc",
                  hintText: "Nhập mã kho, ví dụ: 0001",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedStorageLocs[index] = val.trim();
                  });
                },
              ),
            ],
          );
        }

        final String? currentValue = _selectedStorageLocs[index];

        return DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Chọn kho xuất cho $matId",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          value: currentValue,
          items: filteredStocks.map((stock) {
            return DropdownMenuItem(
              value: stock.storageLocation,
              child: Text(
                "Kho: ${stock.storageLocation} (Tồn: ${stock.availableQty})",
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedStorageLocs[index] = val;
            });
          },
        );
      },
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          minimumSize: Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: _isProcessing ? null : _confirmGoodsIssue,
        child: _isProcessing
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                "XÁC NHẬN XUẤT KHO & TRỪ TỒN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _confirmGoodsIssue() async {
    for (int i = 0; i < widget.items.length; i++) {
      final String moveType = _moveTypeControllers[i]?.text.trim() ?? '';
      final String storageLoc = _selectedStorageLocs[i]?.trim() ?? '';
      if (moveType.isEmpty || storageLoc.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Vui lòng điền Movetype và Storageloc cho tất cả vật tư",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final List<Map<String, dynamic>> giItems = List.generate(
        widget.items.length,
        (i) {
          final item = widget.items[i];
          return {
            "Orderid": widget.orderId,
            "Itemno": item['ItemNo']?.toString() ?? '',
            "Materialid": item['MaterialID']?.toString() ?? '',
            "Plant": item['Plant']?.toString() ?? '',
            "Storageloc": _selectedStorageLocs[i] ?? '',
            "Movetype": _moveTypeControllers[i]?.text.trim() ?? '',
            "Quantity": item['Quantity']?.toString() ?? '0',
            "Baseunit": item['BaseUnit']?.toString() ?? '',
          };
        },
      );

      final Map<String, dynamic> giPayload = _service.buildGoodsIssuePayload(
        orderId: widget.orderId,
        items: giItems,
      );

      final giResult = await _service.createGoodsIssue(giPayload);
      final String matDoc = giResult['Matdoc']?.toString() ?? '';
      _showFinalSuccess(matDoc: matDoc);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi SAP: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showFinalSuccess({required String matDoc}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("Thành công"),
          ],
        ),
        content: Text(
          matDoc.isEmpty
              ? "Post Goods Issue thành công."
              : "Post Goods Issue thành công. Material Document: $matDoc",
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(
              "XÁC NHẬN & VỀ TRANG CHỦ",
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
