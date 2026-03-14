import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Stock.dart';

class StockScreen extends StatefulWidget {
  final String? materialID;
  final String? materialName;

  StockScreen({this.materialID, this.materialName});

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final ODataService _service = ODataService();
  List<StockModel> _allStocks = [];
  List<StockModel> _filteredStocks = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  // Đồng bộ tông màu xanh lá cây Forest & Emerald
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFF2E7D32);
  final Color backgroundLight = Color(0xFFF2F5F2);

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  _loadStockData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchStocks(materialID: widget.materialID);
      setState(() {
        _allStocks = data;
        _filteredStocks = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    setState(() {
      _filteredStocks = _allStocks
          .where(
            (s) =>
                s.storageLocation.toLowerCase().contains(
                  keyword.toLowerCase(),
                ) ||
                s.plant.toLowerCase().contains(keyword.toLowerCase()) ||
                s.materialID.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          _buildElegantHeader(), // Header xanh lá phẳng + Tìm kiếm + Back
          Expanded(
            child: _isLoading ? _buildLoadingSkeleton() : _buildStockList(),
          ),
        ],
      ),
    );
  }

  // --- HEADER PHẲNG ĐỒNG BỘ VỚI TRANG VẬT TƯ ---
  Widget _buildElegantHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 25,
        left: 10,
        right: 20,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
                  widget.materialName ?? "Chi tiết tồn kho",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.materialID != null)
            Padding(
              padding: const EdgeInsets.only(left: 45),
              child: Text(
                'Mã vật tư: ${widget.materialID!.replaceFirst(RegExp(r'^0+'), '')}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 0),
            child: Text(
              "Quản lý và tra cứu danh sách tồn kho hệ thống",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _runFilter,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kho hoặc nhà máy...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    if (_filteredStocks.isEmpty) {
      return Center(child: Text("Không tìm thấy dữ liệu tồn kho."));
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _filteredStocks.length,
      itemBuilder: (context, index) {
        final stock = _filteredStocks[index];
        bool isLow = stock.availableQty < 10;

        // Màu Xanh lục bảo cho an toàn, Màu Vàng hổ phách cho sắp hết (sang trọng)
        Color statusColor = isLow ? Color(0xFFD48806) : Color(0xFF237804);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Thanh màu trạng thái bên trái
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoRow(
                              Icons.warehouse_rounded,
                              "Kho",
                              stock.storageLocation,
                            ),
                            _buildStatusTag(isLow, statusColor),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoRow(
                              Icons.factory_rounded,
                              "Plant",
                              stock.plant,
                            ),
                            _infoRow(
                              Icons.pin_rounded,
                              "ID",
                              stock.materialID.replaceFirst(RegExp(r'^0+'), ''),
                            ),
                          ],
                        ),
                        Divider(
                          height: 30,
                          color: Color(0xFFEDF2ED),
                          thickness: 1.5,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tồn thực tế:",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "${stock.availableQty}",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  stock.baseUnit,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green[200]),
        SizedBox(width: 6),
        Text(
          "$label: ",
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF2E3D31),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(bool low, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        low ? "CẦN NHẬP" : "AN TOÀN",
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 140,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
