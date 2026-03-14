import 'package:flutter/material.dart';
import 'package:sap341/service/ODataService.dart';

class CreateSOScreen extends StatefulWidget {
  @override
  _CreateSOScreenState createState() => _CreateSOScreenState();
}

class _CreateSOScreenState extends State<CreateSOScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ODataService();

  // Controllers cho Form
  TextEditingController _custCtrl = TextEditingController();
  TextEditingController _matCtrl = TextEditingController();
  TextEditingController _qtyCtrl = TextEditingController();
  TextEditingController _plantCtrl = TextEditingController();
  TextEditingController _slocCtrl = TextEditingController();

  _submit() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (c) => Center(child: CircularProgressIndicator()),
      );

      try {
        // 1. Tạo Sales Order
        final result = await _service.createSalesOrder({
          'CustomerID': _custCtrl.text,
          'MaterialID': _matCtrl.text,
          'Quantity': _qtyCtrl.text,
          'Plant': _plantCtrl.text,
          'StorageLocation': _slocCtrl.text,
        });

        // 2. Nếu thành công, tự động gọi Update Stock (Nâng cao)
        // Lưu ý: Logic trừ tồn kho thực tế nên tính toán từ số lượng cũ - số lượng bán
        await _service.updateStock(
          _matCtrl.text,
          _plantCtrl.text,
          _slocCtrl.text,
          0,
        ); // Ví dụ

        Navigator.pop(context); // Tắt loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo SO thành công: ${result['SalesOrderID']}'),
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tạo mới Sales Order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _custCtrl,
              decoration: InputDecoration(labelText: 'Mã khách hàng'),
            ),
            TextFormField(
              controller: _matCtrl,
              decoration: InputDecoration(labelText: 'Mã vật tư'),
            ),
            TextFormField(
              controller: _qtyCtrl,
              decoration: InputDecoration(labelText: 'Số lượng'),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _plantCtrl,
              decoration: InputDecoration(labelText: 'Nhà máy'),
            ),
            TextFormField(
              controller: _slocCtrl,
              decoration: InputDecoration(labelText: 'Kho'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Text('XÁC NHẬN TẠO SO'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
