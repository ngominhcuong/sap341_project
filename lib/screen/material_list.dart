import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Material.dart';
import 'package:sap341/screen/stock.dart';

class MaterialListScreen extends StatefulWidget {
  @override
  _MaterialListScreenState createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final ODataService _service = ODataService();
  List<MaterialModel> _materials = [];
  List<MaterialModel> _filteredMaterials = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  // Tông màu xanh lá cây Forest & Emerald sang trọng
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color accentGreen = Color(0xFF2E7D32);
  final Color backgroundLight = Color(0xFFF2F5F2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchMaterials();
      await Future.delayed(Duration(milliseconds: 600));
      setState(() {
        _materials = data;
        _filteredMaterials = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      _filteredMaterials = _materials
          .where(
            (item) =>
                item.materialName.toLowerCase().contains(
                  enteredKeyword.toLowerCase(),
                ) ||
                item.materialID.toLowerCase().contains(
                  enteredKeyword.toLowerCase(),
                ),
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
          _buildElegantHeader(), // Header nền xanh lá, phẳng, có nút Back
          Expanded(
            child: _isLoading ? _buildLoadingSkeleton() : _buildMaterialList(),
          ),
        ],
      ),
    );
  }

  // --- HEADER PHẲNG (KHÔNG BO GÓC) & CÓ NÚT BACK ---
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
          // Nút Back và Tiêu đề
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
              Text(
                "Danh sách vật tư",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 0),
            child: Text(
              "Quản lý và tra cứu thông tin vật tư hệ thống",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 20),
          // Thanh tìm kiếm cách lề để cân đối với nút Back phía trên
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
                  hintText: 'Tìm kiếm tên hoặc mã vật tư...',
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

  // --- GIỮ NGUYÊN DANH SÁCH & CARD NHƯ TRƯỚC ---
  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 15),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 130,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialList() {
    return RefreshIndicator(
      color: accentGreen,
      onRefresh: () => _loadData(),
      child: ListView.builder(
        padding: EdgeInsets.only(top: 10, bottom: 20),
        itemCount: _filteredMaterials.length,
        itemBuilder: (context, index) {
          final item = _filteredMaterials[index];
          return _buildMaterialCard(item);
        },
      ),
    );
  }

  Widget _buildMaterialCard(MaterialModel item) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockScreen(
                materialID: item.materialID,
                materialName: item.materialName,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.materialName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0D2110),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildTag(item.materialType, accentGreen),
                  ],
                ),
                SizedBox(height: 15),
                Divider(color: Color(0xFFEDF2ED), thickness: 1.5),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecItem(
                      Icons.qr_code_2_rounded,
                      "ID",
                      item.materialID.replaceFirst(RegExp(r'^0+'), ''),
                    ),
                    _buildSpecItem(Icons.scale_rounded, "Unit", item.baseUnit),
                    _buildSpecItem(
                      Icons.warehouse_rounded,
                      "Plant",
                      item.plant.isEmpty ? "All" : item.plant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.green[200]),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF2E3D31),
            ),
          ),
        ],
      ),
    );
  }
}
