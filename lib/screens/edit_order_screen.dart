import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_state.dart';
import '../models/invoice_model.dart';
import '../utils/order_parser.dart';
import '../services/storage_service.dart';
import 'invoice_screen.dart';

class EditOrderScreen extends ConsumerStatefulWidget {
  const EditOrderScreen({super.key});

  @override
  ConsumerState<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends ConsumerState<EditOrderScreen> {
  final _customerNameController = TextEditingController();
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _priceControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    for (final controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    final invoice = ref.read(appStateProvider);
    _customerNameController.text = invoice.customerName;
    
    _nameControllers.clear();
    _quantityControllers.clear();
    _priceControllers.clear();
    
    // Nếu không có items, tạo một item trống
    if (invoice.items.isEmpty) {
      _nameControllers.add(TextEditingController());
      _quantityControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
    } else {
      for (final item in invoice.items) {
        _nameControllers.add(TextEditingController(text: item.name));
        _quantityControllers.add(TextEditingController(text: item.quantity.toString()));
        // Hiển thị giá đúng định dạng (chia cho 1000 để về đơn vị nghìn)
        final displayPrice = item.price / 1000;
        _priceControllers.add(TextEditingController(text: displayPrice.toString()));
      }
    }
    
    // Cập nhật UI sau khi khởi tạo controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _addItem() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _quantityControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _nameControllers[index].dispose();
      _quantityControllers[index].dispose();
      _priceControllers[index].dispose();
      _nameControllers.removeAt(index);
      _quantityControllers.removeAt(index);
      _priceControllers.removeAt(index);
    });
  }

  void _updateInvoice() {
    final items = <InvoiceItem>[];
    
    for (int i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      final quantityText = _quantityControllers[i].text.trim();
      final priceText = _priceControllers[i].text.trim();
      
      if (name.isNotEmpty && quantityText.isNotEmpty && priceText.isNotEmpty) {
        try {
          final quantity = int.parse(quantityText);
          final price = double.parse(priceText) * 1000; // Chuyển sang VND
          final total = quantity * price;
          
          items.add(InvoiceItem(
            name: name,
            quantity: quantity,
            price: price,
            total: total,
          ));
        } catch (e) {
          // Bỏ qua item không hợp lệ
        }
      }
    }
    
    final invoice = InvoiceModel(
      customerName: _customerNameController.text.trim(),
      items: items,
    );
    
    ref.read(appStateProvider.notifier).setInvoice(invoice);
  }

  void _printInvoice() async {
    _updateInvoice();
    final invoice = ref.read(appStateProvider);
    
    // Lưu hóa đơn vào lịch sử
    try {
      await StorageService.saveInvoice(invoice);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hóa đơn đã được lưu vào lịch sử'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu hóa đơn: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(appStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Đơn Hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _printInvoice,
            icon: const Icon(Icons.print),
            tooltip: 'In Hóa Đơn',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                      onChanged: (value) => _updateInvoice(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh Sách Sản Phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Sản Phẩm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_nameControllers.isNotEmpty)
                      Column(
                        children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 1, child: Text('TT', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Số Lượng', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text('Tên Sản Phẩm', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Đơn Giá', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text('Thành Tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                                Expanded(flex: 1, child: Text('Thao Tác', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ),
                          // Table rows
                          ...List.generate(_nameControllers.length, (index) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text('${index + 1}'),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _quantityControllers[index],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _updateInvoice(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: _nameControllers[index],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      onChanged: (value) => _updateInvoice(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _priceControllers[index],
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => _updateInvoice(),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      OrderParser.formatTotal(_calculateItemTotal(index)),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: IconButton(
                                      onPressed: () => _removeItem(index),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Xóa',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Chưa có sản phẩm nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
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
                  children: [
                    const Text(
                      'Tổng Cộng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      OrderParser.formatTotal(invoice.totalAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _printInvoice,
              icon: const Icon(Icons.print),
              label: const Text('In Hóa Đơn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateItemTotal(int index) {
    try {
      final quantity = int.parse(_quantityControllers[index].text);
      final price = double.parse(_priceControllers[index].text) * 1000;
      return quantity * price;
    } catch (e) {
      return 0;
    }
  }
}
