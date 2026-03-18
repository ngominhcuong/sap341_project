import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sap341/service/ODataService.dart';

class SalesOrderListScreen extends StatefulWidget {
  const SalesOrderListScreen({super.key});

  @override
  State<SalesOrderListScreen> createState() => _SalesOrderListScreenState();
}

class _SalesOrderListScreenState extends State<SalesOrderListScreen> {
  final ODataService _service = ODataService();

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  List<Map<String, dynamic>> _pagedOrders = [];

  List<String> _docTypeOptions = ['Tất cả'];
  List<String> _salesOrgOptions = ['Tất cả'];

  String _selectedDocType = 'Tất cả';
  String _selectedSalesOrg = 'Tất cả';
  String _searchKeyword = '';

  bool _isLoading = true;
  bool _isFilterExpanded = false;
  int _currentPage = 1;
  final int _pageSize = 10;

  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color accentGreen = const Color(0xFF2E7D32);
  final Color backgroundLight = const Color(0xFFF2F5F2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final orders = await _service.fetchSalesOrders(top: 50);

      if (!mounted) return;
      setState(() {
        _allOrders = orders;

        _docTypeOptions = [
          'Tất cả',
          ...orders
              .map((e) => _field(e, ['Doctype', 'doctype', 'AUART']))
              .where((v) => v.isNotEmpty)
              .toSet(),
        ];

        _salesOrgOptions = [
          'Tất cả',
          ...orders
              .map((e) => _field(e, ['Salesorg', 'salesorg', 'VKORG']))
              .where((v) => v.isNotEmpty)
              .toSet(),
        ];

        _runFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi SAP: $e');
    }
  }

  void _runFilter() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final orderId = _field(order, ['Orderid', 'orderid', 'VBELN']);
        final customerId = _field(order, ['Customerid', 'customerid', 'KUNNR']);
        final customerName = _field(order, [
          'Customername',
          'customername',
          'NAME1',
        ]);
        final docType = _field(order, ['Doctype', 'doctype', 'AUART']);
        final salesOrg = _field(order, ['Salesorg', 'salesorg', 'VKORG']);

        final keyword = _searchKeyword.toLowerCase();
        final matchesSearch =
            orderId.toLowerCase().contains(keyword) ||
            customerId.toLowerCase().contains(keyword) ||
            customerName.toLowerCase().contains(keyword);

        final matchesDocType =
            _selectedDocType == 'Tất cả' || docType == _selectedDocType;
        final matchesSalesOrg =
            _selectedSalesOrg == 'Tất cả' || salesOrg == _selectedSalesOrg;

        return matchesSearch && matchesDocType && matchesSalesOrg;
      }).toList();

      _currentPage = 1;
      _updatePagedList();
    });
  }

  void _updatePagedList() {
    final start = (_currentPage - 1) * _pageSize;
    int end = start + _pageSize;
    if (end > _filteredOrders.length) end = _filteredOrders.length;

    setState(() {
      _pagedOrders = _filteredOrders.isEmpty
          ? []
          : _filteredOrders.sublist(start, end);
    });
  }

  String _field(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _itemsOf(Map<String, dynamic> order) {
    final dynamic value =
        order[ODataService.salesOrderItemsNavProperty] ??
        order['To_Items'] ??
        order['to_items'];

    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _formatDateTime(String rawValue) {
    if (rawValue.trim().isEmpty) return '-';
    final value = rawValue.trim();

    DateTime? parsed;

    final odataDate = RegExp(r'/Date\((\d+)\)/').firstMatch(value);
    if (odataDate != null) {
      final millis = int.tryParse(odataDate.group(1) ?? '');
      if (millis != null) {
        parsed = DateTime.fromMillisecondsSinceEpoch(millis);
      }
    }

    if (parsed == null && RegExp(r'^\d{8}$').hasMatch(value)) {
      final yyyy = int.parse(value.substring(0, 4));
      final mm = int.parse(value.substring(4, 6));
      final dd = int.parse(value.substring(6, 8));
      parsed = DateTime(yyyy, mm, dd);
    }

    parsed ??= DateTime.tryParse(value);
    if (parsed == null) return rawValue;

    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredOrders.length / _pageSize).ceil();

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
                          duration: const Duration(milliseconds: 350),
                          child: _buildSalesOrderList(
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
              const Expanded(
                child: Text(
                  'View Sales Order',
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
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: Colors.white),
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
        onChanged: (value) {
          _searchKeyword = value;
          _runFilter();
        },
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Tìm theo SO / Customer ID / Customer Name...',
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
                  ? 'Ẩn bộ lọc nâng cao'
                  : 'Lọc theo Loại đơn & Sales Org',
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
              'Doc Type',
              _docTypeOptions,
              _selectedDocType,
              (v) {
                setState(() => _selectedDocType = v!);
                _runFilter();
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildLabeledFilter(
              'Sales Org',
              _salesOrgOptions,
              _selectedSalesOrg,
              (v) {
                setState(() => _selectedSalesOrg = v!);
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

  Widget _buildSalesOrderList({Key? key}) {
    if (_pagedOrders.isEmpty) {
      return const Center(child: Text('Không tìm thấy dữ liệu'));
    }

    return ListView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _pagedOrders.length,
      itemBuilder: (context, index) =>
          _buildSalesOrderCard(_pagedOrders[index]),
    );
  }

  Widget _buildSalesOrderCard(Map<String, dynamic> order) {
    final orderId = _field(order, ['Orderid', 'orderid', 'VBELN']);
    final customerName = _field(order, [
      'Customername',
      'customername',
      'NAME1',
    ]);
    final customerId = _field(order, ['Customerid', 'customerid', 'KUNNR']);
    final docType = _field(order, ['Doctype', 'doctype', 'AUART']);
    final createdOnRaw = _field(order, ['Createdon', 'createdon', 'ERDAT']);
    final createdOn = _formatDateTime(createdOnRaw);
    final netValue = _field(order, ['Netvalue', 'netvalue']);
    final currency = _field(order, ['Currency', 'currency', 'WAERK']);
    final items = _itemsOf(order);

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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: accentGreen.withOpacity(0.12),
          child: Icon(Icons.receipt_long, color: accentGreen),
        ),
        title: Text(
          orderId.isEmpty ? 'SO: -' : 'SO: $orderId',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          customerName.isEmpty
              ? 'Customer: $customerId'
              : '$customerName ($customerId)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          const Divider(color: Color(0xFFEDF2ED), thickness: 1.2),
          const SizedBox(height: 10),
          _buildDetailRow('Doc Type', docType),
          _buildDetailRow('Created On', createdOn),
          _buildDetailRow(
            'Net Value',
            netValue.isEmpty
                ? '-'
                : '$netValue ${currency.isEmpty ? '' : currency}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Items (${items.length})',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Không có item'),
            )
          else
            ...items.map(_buildItemRow),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final itemNo = _field(item, ['Itemno', 'itemno', 'POSNR']);
    final material = _field(item, ['Materialid', 'materialid', 'MATNR']);
    final plant = _field(item, ['Plant', 'plant', 'WERKS']);
    final quantity = _field(item, ['Quantity', 'quantity', 'KWMENG']);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0EDE0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                itemNo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 160,
              child: Text(
                material,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 62, child: Text(plant)),
            SizedBox(
              width: 72,
              child: Text(
                quantity,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
