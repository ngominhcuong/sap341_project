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

  // Quản lý kho đã chọn theo chỉ mục dòng (index)
  Map<int, StockModel?> _selectedStocks = {};

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFF2E7D32);

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

  // ... (Các widget _buildOrderSummary giữ nguyên như code của bạn)
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
            "Vui lòng chọn kho xuất cho từng vật tư bên dưới",
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
        final selectedStock = _selectedStocks[index];

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
                    _buildStockPicker(index, item['MaterialID'], item['Plant']),
                    if (selectedStock != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tồn kho hiện tại:",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "${selectedStock.availableQty} ${selectedStock.baseUnit}",
                              style: TextStyle(
                                color: accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStockPicker(int index, String matId, String plant) {
    return FutureBuilder<List<StockModel>>(
      key: ValueKey('picker_${matId}_$index'),
      future: _service.fetchStocks(materialID: matId, plant: plant),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        List<StockModel> allStocks = snapshot.data!;
        List<StockModel> filteredStocks = allStocks
            .where((s) => s.materialID == matId)
            .toList();

        if (filteredStocks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Không có kho cho vật tư này",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        StockModel? currentValue;
        if (_selectedStocks[index] != null) {
          try {
            currentValue = filteredStocks.firstWhere(
              (s) =>
                  s.storageLocation == _selectedStocks[index]!.storageLocation,
            );
          } catch (e) {
            currentValue = null;
          }
        }

        return DropdownButtonFormField<StockModel>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Chọn kho xuất cho $matId",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          value: currentValue,
          items: filteredStocks.map((stock) {
            return DropdownMenuItem(
              value: stock,
              child: Text(
                "Kho: ${stock.storageLocation} (Tồn: ${stock.availableQty})",
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedStocks[index] = val;
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

  // --- PHẦN LOGIC QUAN TRỌNG NHẤT: TRỪ TỒN THẬT ---
  Future<void> _confirmGoodsIssue() async {
    // 1. Kiểm tra xem tất cả các dòng đã chọn kho chưa
    if (_selectedStocks.values.where((v) => v != null).length <
        widget.items.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng chọn đầy đủ kho cho các vật tư"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 2. Chạy vòng lặp để gọi PUT request cho từng Item (vì update_entity xử lý từng entry)
      for (int i = 0; i < widget.items.length; i++) {
        final item = widget.items[i];
        final stock = _selectedStocks[i]!;

        // Payload phải khớp hoàn toàn với cấu trúc zst_382_stockupdate trong ABAP của bạn
        Map<String, dynamic> updatePayload = {
          "Materialid": item['MaterialID'],
          "Plant": item['Plant'],
          "Storageloc": stock.storageLocation, // ls_item-stge_loc
          "Movetype":
              "551", // Hoặc mã move type bạn quy định (thường là 201 hoặc 601)
          "Quantity": item['Quantity'].toString(),
          "Baseunit": item['BaseUnit'],
        };

        // GỌI API THỰC TẾ (Sử dụng phương thức UPDATE/PUT)
        // Lưu ý: Endpoint thường có dạng StockUpdateSet(Materialid='...', Plant='...', ...)
        // tùy theo cách bạn định nghĩa Key trong SEGW.
        await _service.updateStock(updatePayload);
      }

      // 3. Cập nhật UI trừ tồn "ảo" để người dùng thấy số thay đổi ngay lập tức
      setState(() {
        for (int i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];
          final qty = double.tryParse(item['Quantity'].toString()) ?? 0;
          _selectedStocks[i]?.availableQty -= qty;
        }
      });

      _showFinalSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi SAP: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showFinalSuccess() {
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
          "Hệ thống đã thực hiện Goods Issue và cập nhật số dư kho SAP thực tế.",
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
