import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Stock.dart';

class StockScreen extends StatefulWidget {
  final String? materialID;
  final String? materialName;
  final String? plant;

  const StockScreen({Key? key, this.materialID, this.materialName, this.plant})
    : super(key: key);

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final ODataService _service = ODataService();

  List<StockModel> _allStocks = [];
  List<StockModel> _filteredStocks = [];
  List<StockModel> _pagedStocks = [];

  List<String> _locationOptions = ['Tất cả'];
  List<String> _plantOptions = ['Tất cả'];

  String _selectedLocation = 'Tất cả';
  String _selectedPlant = 'Tất cả';
  String _searchKeyword = '';

  bool _isLoading = true;
  bool _isFilterExpanded = false;
  int _currentPage = 1;
  final int _pageSize = 5;

  final TextEditingController _searchController = TextEditingController();

  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color accentGreen = const Color(0xFF2E7D32);
  final Color backgroundLight = const Color(0xFFF2F5F2);

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  // --- LOGIC DỮ LIỆU ---
  Future<void> _loadStockData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Gọi service: Nếu materialID null, service sẽ lấy toàn bộ StockSet
      final data = await _service.fetchStocks(
        materialID: widget.materialID,
        plant: widget.plant,
      );

      if (mounted) {
        setState(() {
          _allStocks = data;

          // Cập nhật danh sách options cho Dropdown từ dữ liệu thật
          _locationOptions = [
            'Tất cả',
            ...data.map((e) => e.storageLocation).toSet().toList()..sort(),
          ];
          _plantOptions = [
            'Tất cả',
            ...data.map((e) => e.plant).toSet().toList()..sort(),
          ];

          _runFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Lỗi tải tồn kho: $e");
      }
    }
  }

  void _runFilter() {
    setState(() {
      _filteredStocks = _allStocks.where((item) {
        // Lọc theo từ khóa (Mã vật tư hoặc Vị trí kho)
        final matchesSearch =
            item.materialID.toLowerCase().contains(
              _searchKeyword.toLowerCase(),
            ) ||
            item.storageLocation.toLowerCase().contains(
              _searchKeyword.toLowerCase(),
            );

        final matchesLoc =
            _selectedLocation == 'Tất cả' ||
            item.storageLocation == _selectedLocation;

        final matchesPlant =
            _selectedPlant == 'Tất cả' || item.plant == _selectedPlant;

        return matchesSearch && matchesLoc && matchesPlant;
      }).toList();

      _currentPage = 1;
      _updatePagedList();
    });
  }

  void _updatePagedList() {
    int start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (end > _filteredStocks.length) end = _filteredStocks.length;

    setState(() {
      _pagedStocks = _filteredStocks.isEmpty
          ? []
          : _filteredStocks.sublist(start, end);
    });
  }

  void _goToPage(int p) {
    if (p != _currentPage) {
      setState(() {
        _currentPage = p;
        _updatePagedList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPages = (_filteredStocks.length / _pageSize).ceil();

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
                          child: _buildStockList(
                            key: ValueKey(
                              'page_$_currentPage' +
                                  '_len_${_filteredStocks.length}',
                            ),
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

  // --- UI COMPONENTS ---

  Widget _buildElegantHeader() {
    // Xóa số 0 thừa phía trước mã vật tư để hiển thị đẹp hơn
    String displayID =
        (widget.materialID != null && widget.materialID != "null")
        ? widget.materialID!.replaceFirst(RegExp(r'^0+'), '')
        : "";

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.materialName ?? "Danh mục Tồn kho",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayID.isNotEmpty)
                      Text(
                        "Mã VT: $displayID",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildSearchBox(),
          _buildFilterToggle(),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
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
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          _searchKeyword = v;
          _runFilter();
        },
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Tìm nhanh theo mã hoặc kho...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterToggle() {
    return InkWell(
      onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isFilterExpanded ? Icons.keyboard_arrow_up : Icons.tune,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Text(
              "Bộ lọc nâng cao",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildLabeledFilter(
              "Kho",
              _locationOptions,
              _selectedLocation,
              (v) {
                setState(() => _selectedLocation = v!);
                _runFilter();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildLabeledFilter(
              "Nhà máy",
              _plantOptions,
              _selectedPlant,
              (v) {
                setState(() => _selectedPlant = v!);
                _runFilter();
              },
            ),
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
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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

  Widget _buildStockList({Key? key}) {
    if (_pagedStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              "Không tìm thấy dữ liệu tồn kho",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _pagedStocks.length,
      itemBuilder: (context, index) => _buildStockCard(_pagedStocks[index]),
    );
  }

  Widget _buildStockCard(StockModel stock) {
    double qty = double.tryParse(stock.availableQty.toString()) ?? 0;
    bool isLow = qty < 10;
    Color statusColor = isLow
        ? const Color(0xFFD48806)
        : const Color(0xFF237804);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _infoRow(
                            Icons.qr_code_2_rounded,
                            "Mã VT",
                            stock.materialID.replaceFirst(RegExp(r'^0+'), ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusTag(isLow, statusColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _infoRow(
                            Icons.warehouse_rounded,
                            "Kho",
                            stock.storageLocation,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _infoRow(
                            Icons.factory_outlined,
                            "Plant",
                            stock.plant,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 25, color: Color(0xFFF0F0F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tồn khả dụng:",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${stock.availableQty}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stock.baseUnit,
                              style: TextStyle(
                                fontSize: 12,
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
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: accentGreen.withOpacity(0.5)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            "$label: ",
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Color(0xFF2E3D31),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTag(bool low, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        low ? "CẢNH BÁO" : "BÌNH THƯỜNG",
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- PHÂN TRANG ---
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

  Widget _buildLoadingSkeleton() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: ListView.builder(
      itemCount: 4,
      padding: const EdgeInsets.all(15),
      itemBuilder: (_, __) => Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    ),
  );

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
}
