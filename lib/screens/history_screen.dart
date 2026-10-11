import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/app_state.dart';
import '../services/storage_service.dart';
import 'invoice_screen.dart';
import 'order_form_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime selectedDate = DateTime.now();
  List<InvoiceModel> invoices = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      isLoading = true;
    });

    try {
      invoices = await StorageService.getInvoicesByDate(selectedDate);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadInvoices();
    }
  }

  Future<void> _deleteInvoice(int index) async {
    await StorageService.deleteInvoice(selectedDate, index);
    _loadInvoices();
  }

  void _printInvoice(InvoiceModel invoice) {
    ref.read(appStateProvider.notifier).setInvoice(invoice);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceScreen(),
      ),
    );
  }

  void _editInvoice(InvoiceModel invoice) {
    final orderText = _convertInvoiceToOrderText(invoice);
    final invoiceIndex = invoices.indexOf(invoice);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderFormScreen(
          editData: {
            'customerName': invoice.customerName,
            'orderText': orderText,
            'isEditMode': 'true',
            'editDate': selectedDate.toIso8601String(),
            'editIndex': invoiceIndex.toString(),
          },
        ),
      ),
    ).then((_) {
      // Reload danh sách sau khi edit xong
      _loadInvoices();
    });
  }

  String _convertInvoiceToOrderText(InvoiceModel invoice) {
    // Chuyển đổi InvoiceItems thành format text như "12 leo x1.2"
    final orderLines = <String>[];
    
    for (final item in invoice.items) {
      // Chuyển đổi giá từ VND về nghìn đồng
      final priceInK = item.price / 1000;
      final formattedPrice = priceInK % 1 == 0 
          ? priceInK.toInt().toString()
          : priceInK.toString();
      
      // Format: "quantity productName x price"
      orderLines.add('${item.quantity} ${item.name} x$formattedPrice');
    }
    
    return orderLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đơn Hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Chọn Ngày'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Invoices List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : invoices.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không có hóa đơn nào trong ngày này',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = invoices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                invoice.customerName.isNotEmpty
                                    ? invoice.customerName
                                    : 'Khách hàng không tên',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Số lượng sản phẩm: ${invoice.items.length}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tổng tiền: ${_formatPrice(invoice.totalAmount)}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Thời gian: ${DateFormat('HH:mm').format(invoice.createdAt)}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editInvoice(invoice);
                                      break;
                                    case 'print':
                                      _printInvoice(invoice);
                                      break;
                                    case 'delete':
                                      _showDeleteDialog(index);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('Sửa'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'print',
                                    child: Row(
                                      children: [
                                        Icon(Icons.print, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('In lại'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Xóa'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(price.toInt());
    // Thay dấu phẩy bằng dấu chấm để hiển thị như 15.000
    return '${formatted.replaceAll(',', '.')} VND';
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hóa đơn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteInvoice(index);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
