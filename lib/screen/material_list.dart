import 'package:flutter/material.dart';
import 'package:sap341/service/ODataService.dart';
import 'package:sap341/model/Material.dart';
import 'package:sap341/screen/stock.dart';

class MaterialListScreen extends StatefulWidget {
  @override
  _MaterialListScreenState createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  final ODataService _service = ODataService();

  List<MaterialModel> _materials = []; // Danh sách gốc từ SAP
  List<MaterialModel> _filteredMaterials =
      []; // Danh sách để hiển thị lên màn hình
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.fetchMaterials();
      setState(() {
        _materials = data;
        _filteredMaterials = data; // Ban đầu hiển thị tất cả
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi: $e");
    }
  }

  void _runFilter(String enteredKeyword) {
    List<MaterialModel> results = [];
    if (enteredKeyword.isEmpty) {
      results = _materials;
    } else {
      results = _materials
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
    }

    setState(() {
      _filteredMaterials = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _runFilter(value), // Lọc ngay khi gõ
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc ID...',
              prefixIcon: Icon(Icons.search, color: Colors.blue),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredMaterials.length, // Dùng danh sách đã lọc
              itemBuilder: (context, index) {
                final item = _filteredMaterials[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(item.materialType)),
                  title: Text(item.materialName),
                  subtitle: Text(
                    'ID: ${item.materialID} | Plant: ${item.plant}',
                  ),
                  onTap: () {
                    // Loại bỏ các số 0 ở đầu (Leading zeros) để SAP dễ nhận diện filter
                    String formattedID = item.materialID.replaceFirst(
                      RegExp(r'^0+'),
                      '',
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockScreen(
                          materialID: formattedID,
                          materialName: item.materialName,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
