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
  List<MaterialModel> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData({String? search}) async {
    setState(() => _isLoading = true);
    final data = await _service.fetchMaterials(search: search);
    setState(() {
      _materials = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Tìm vật tư...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) => _loadData(search: value),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final item = _materials[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(item.materialType)),
                  title: Text(item.materialName),
                  subtitle: Text(
                    'ID: ${item.materialID} | Plant: ${item.plant}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => StockScreen(materialID: item.materialID),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
