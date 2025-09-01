import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_state.dart';
import '../models/invoice_model.dart';
import '../utils/order_parser.dart';
import '../services/storage_service.dart';
import 'edit_order_screen.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key});

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _orderInfoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _orderInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final formData = await StorageService.getFormData();
    _customerNameController.text = formData['customerName'] ?? '';
    _orderInfoController.text = formData['orderInfo'] ?? '';
  }

  Future<void> _saveData() async {
    await StorageService.saveFormData(
      _customerNameController.text,
      _orderInfoController.text,
    );
  }

  Future<void> _clearSavedData() async {
    await StorageService.clearFormData();
  }

  void _processOrder() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customerName = _customerNameController.text.trim();
      final orderText = _orderInfoController.text.trim();
      
      final items = OrderParser.parseOrderText(orderText);
      
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể parse đơn hàng. Vui lòng kiểm tra định dạng.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final invoice = InvoiceModel(
        customerName: customerName,
        items: items,
      );

      ref.read(appStateProvider.notifier).setInvoice(invoice);
      
      // Xóa dữ liệu đã lưu
      _clearSavedData();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EditOrderScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Thông Tin Đơn Hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông Tin Khách Hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên Khách Hàng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên khách hàng';
                          }
                          return null;
                        },
                        onChanged: (value) => _saveData(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông Tin Đơn Hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orderInfoController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Thông Tin Đơn Hàng',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_cart),
                          hintText: 'Ví dụ:\n20 leo x 1.2\n30 bap x 2',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập thông tin đơn hàng';
                          }
                          return null;
                        },
                        onChanged: (value) => _saveData(),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hướng Dẫn Định Dạng:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('• 20 leo x 1.2'),
                            Text('• 30 bap x 2'),
                            Text('• 15 me x 0.8'),
                            SizedBox(height: 4),
                            Text(
                              'Lưu ý: Đơn giá sẽ được nhân 1000 để chuyển sang VND',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _processOrder,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(_isLoading ? 'Đang xử lý...' : 'Tiếp Tục'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _customerNameController.clear();
                      _orderInfoController.clear();
                      _clearSavedData();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Xóa Form'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
