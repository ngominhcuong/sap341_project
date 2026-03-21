import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Material.dart';
import 'package:sap341/screen/stock.dart';

class MaterialListScreen extends StatefulWidget {
  final bool isPicker;
  const MaterialListScreen({Key? key, this.isPicker = false}) : super(key: key);

  @override
  _MaterialListScreenState createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final ODataService _service = ODataService();

  List<MaterialModel> _allMaterials = [];
  List<MaterialModel> _filteredMaterials = [];
  List<MaterialModel> _pagedMaterials = [];

  List<String> _unitOptions = ['Tất cả'];
  List<String> _plantOptions = ['Tất cả'];

  String _selectedUnit = 'Tất cả';
  String _selectedPlant = 'Tất cả';
  String _searchKeyword = '';

  bool _isLoading = true;
  bool _isFilterExpanded = false; // Trạng thái đóng/mở bộ lọc
  int _currentPage = 1;
  final int _pageSize = 10;

  TextEditingController _searchController = TextEditingController();

  // Palette màu sắc từ ví dụ của bạn
  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color accentGreen = const Color(0xFF2E7D32);
  final Color backgroundLight = const Color(0xFFF2F5F2);
  final Color darkText = const Color(0xFF0D2110);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LOGIC DỮ LIỆU ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchMaterials();
      if (mounted) {
        setState(() {
          _allMaterials = data;
          _unitOptions = [
            'Tất cả',
            ...data.map((e) => e.baseUnit).toSet().toList(),
          ];
          _plantOptions = [
            'Tất cả',
            ...data
                .map((e) => e.plant.isEmpty ? "MI00" : e.plant)
                .toSet()
                .toList(),
          ];
          _runFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Lỗi SAP: $e");
      }
    }
  }

  void _runFilter() {
    setState(() {
      _filteredMaterials = _allMaterials.where((item) {
        final matchesSearch =
            item.materialName.toLowerCase().contains(
              _searchKeyword.toLowerCase(),
            ) ||
            item.materialID.toLowerCase().contains(
              _searchKeyword.toLowerCase(),
            );
        final matchesUnit =
            _selectedUnit == 'Tất cả' || item.baseUnit == _selectedUnit;
        final itemPlant = item.plant;
        final matchesPlant =
            _selectedPlant == 'Tất cả' || itemPlant == _selectedPlant;
        return matchesSearch && matchesUnit && matchesPlant;
      }).toList();

      _currentPage = 1;
      _updatePagedList();
    });
  }

  void _updatePagedList() {
    int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (end > _filteredMaterials.length) end = _filteredMaterials.length;

    setState(() {
      _pagedMaterials = _filteredMaterials.isEmpty
          ? []
          : _filteredMaterials.sublist(start, end);
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_filteredMaterials.length / _pageSize).ceil();

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Column(
        children: [
          _buildElegantHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingSkeleton()
                : Column(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _buildMaterialList(
                            key: ValueKey(_currentPage),
                          ),
                        ),
                      ),
                      if (totalPages > 1) _buildSlidingPagination(totalPages),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // --- UI: HEADER & BỘ LỌC THU GỌN ---
  Widget _buildElegantHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 15,
        right: 15,
      ),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.isPicker ? "Chọn Vật Tư" : "Kho Vật Tư SAP",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSearchBox(),
          _buildFilterToggle(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isFilterExpanded
                ? _buildExpandedFilters()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          _searchKeyword = v.trim();
          _runFilter();
        },
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm vật tư...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterToggle() {
    return InkWell(
      onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isFilterExpanded ? Icons.keyboard_arrow_up : Icons.tune,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isFilterExpanded
                  ? "Ẩn bộ lọc nâng cao"
                  : "Lọc theo Đơn vị & Nhà máy",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildLabeledFilter(
              "Base Unit",
              _unitOptions,
              _selectedUnit,
              (v) {
                setState(() => _selectedUnit = v!);
                _runFilter();
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildLabeledFilter("Plant", _plantOptions, _selectedPlant, (
              v,
            ) {
              setState(() => _selectedPlant = v!);
              _runFilter();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledFilter(
    String label,
    List<String> options,
    String currentVal,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              items: options
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // --- UI: CARD VẬT TƯ CHI TIẾT (PHIÊN BẢN CŨ NÂNG CẤP) ---
  Widget _buildMaterialList({Key? key}) {
    if (_pagedMaterials.isEmpty)
      return const Center(child: Text("Không tìm thấy dữ liệu"));
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _pagedMaterials.length,
      itemBuilder: (context, index) =>
          _buildMaterialCard(_pagedMaterials[index]),
    );
  }

  Widget _buildMaterialCard(MaterialModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (widget.isPicker) {
              // Nếu là chế độ chọn vật tư (cho đơn hàng), trả về item
              Navigator.pop(context, item);
            } else {
              // Mở tồn kho theo đúng vật tư được chọn.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StockScreen(
                    materialID: item.materialID,
                    materialName: item.materialName,
                    plant: item.plant,
                  ),
                ),
              );
            }
          },
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
                          fontSize: 17,
                          color: darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildTag(item.materialType, accentGreen),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(color: Color(0xFFEDF2ED), thickness: 1.5),
                const SizedBox(height: 15),
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
                      item.plant.isEmpty ? "MI00" : item.plant,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          fontSize: 10,
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
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF2E3D31),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- UI: PHÂN TRANG SLIDING << < 1 2 3 4 5 > >> ---
  Widget _buildSlidingPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pageIconBtn(
              Icons.first_page,
              () => _goToPage(1),
              _currentPage > 1,
            ),
            _pageIconBtn(
              Icons.chevron_left,
              () => _goToPage(_currentPage - 1),
              _currentPage > 1,
            ),
            ..._generateVisiblePages(totalPages).map((p) => _pageNumberBtn(p)),
            _pageIconBtn(
              Icons.chevron_right,
              () => _goToPage(_currentPage + 1),
              _currentPage < totalPages,
            ),
            _pageIconBtn(
              Icons.last_page,
              () => _goToPage(totalPages),
              _currentPage < totalPages,
            ),
          ],
        ),
      ),
    );
  }

  List<int> _generateVisiblePages(int totalPages) {
    int start = (_currentPage - 1).clamp(1, totalPages);
    int end = (start + 2).clamp(1, totalPages);
    if (end - start < 2) start = (end - 2).clamp(1, totalPages);
    List<int> pages = [];
    for (int i = start; i <= end; i++) pages.add(i);
    return pages;
  }

  Widget _pageNumberBtn(int page) {
    bool isSelected = _currentPage == page;
    return GestureDetector(
      onTap: () => _goToPage(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? accentGreen : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          "$page",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _pageIconBtn(IconData icon, VoidCallback onTap, bool enabled) {
    return IconButton(
      icon: Icon(
        icon,
        color: enabled ? accentGreen : Colors.grey.shade300,
        size: 20,
      ),
      onPressed: enabled ? onTap : null,
    );
  }

  void _goToPage(int p) {
    if (p == _currentPage) return;
    setState(() {
      _currentPage = p;
      _updatePagedList();
    });
  }

  Widget _buildLoadingSkeleton() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        height: 120,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  );

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
}
