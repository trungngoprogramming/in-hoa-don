import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
                    onPressed: () => _printBlankInvoice(context),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('In Hóa Đơn Trống'),
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
            ],
          ),
        ),
      ),
    );
  }

  void _printBlankInvoice(BuildContext context) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await _generateBlankPdf(),
    );
  }

  Future<Uint8List> _generateBlankPdf() async {
    final pdf = pw.Document();
    
    // Tải font Carlito (tương tự Calibri) từ assets - hoạt động offline trong APK
    pw.Font? regularFont;
    pw.Font? boldFont;
    
    try {
      // Tải font Carlito Regular và Bold từ assets
      final regularFontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Carlito-Bold.ttf");
      
      regularFont = pw.Font.ttf(regularFontData);
      boldFont = pw.Font.ttf(boldFontData);
      print('✅ Loaded Carlito fonts from assets - Vietnamese supported, works offline');
    } catch (e) {
      print('❌ Cannot load Carlito font from assets: $e');
      
      // Fallback to Noto Sans from assets
      try {
        final notoFontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
        regularFont = pw.Font.ttf(notoFontData);
        boldFont = pw.Font.ttf(notoFontData); // Sử dụng cùng font cho bold
        print('✅ Loaded Noto Sans font as fallback from assets');
      } catch (e2) {
        print('❌ Cannot load any font from assets: $e2');
        print('⚠️ Using default PDF font - Vietnamese characters may not display correctly');
      }
    }
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(15),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(
                  'BÁNH KẸO HÙNG CHÍNH',
                  style: _createTextStyle(
                    fontSize: 20,
                    font: boldFont, // Sử dụng boldFont cho tiêu đề
                  ),
                ),
              ),
              
              pw.SizedBox(height: 5),
              
              // Company Info
              pw.Text(
                'ĐC: 139/1 Tôn Đản, TP. Đà Nẵng * ĐT: 0905070472 - 0344678772',
                style: _createTextStyle(
                fontSize: 12,
                font: regularFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 3),
              
              pw.Text(
                'Chuyên bán: BÁNH ĐẬU XANH, BÁNH DỪA NƯỚNG, KHÔ MÈ, MÈ XỬNG, KẸO ĐẬU,',
                style: _createTextStyle(
                  fontSize: 10,
                  font: regularFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'KẸO DỒI, BẮP, NUI, ME, CỐM, THÈO LÈO, CHUỐI SẤY, BÁNH THÁNH, BÁNH MEN...',
                style: _createTextStyle(
                  fontSize: 10,
                  font: regularFont,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 10),
              
              // Customer and Date Info - BLANK with underscores
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Khách hàng: _______________________',
                    style: _createTextStyle(
                      fontSize: 10,
                      font: regularFont,
                    ),
                  ),
                  pw.Text(
                    'Ngày: _______________',
                    style: _createTextStyle(
                      fontSize: 10,
                      font: regularFont,
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 10),
              
              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: const {
                  0: pw.FixedColumnWidth(25),
                  1: pw.FlexColumnWidth(4),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  // Header
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'TT',
                            style: _createTextStyle(
                              fontSize: 10,
                              font: boldFont,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'SL x TÊN HÀNG',
                            style: _createTextStyle(
                              fontSize: 10,
                              font: boldFont,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'ĐƠN GIÁ',
                            style: _createTextStyle(
                              fontSize: 10,
                              font: boldFont,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'THÀNH TIỀN',
                            style: _createTextStyle(
                              fontSize: 10,
                              font: boldFont,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Empty rows for filling by hand
                  ...List.generate(20, (index) {
                    return pw.TableRow(
                      children: [
                        pw.Container(
                          height: 20,
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Center(
                            child: pw.Text(
                              '${index + 1}',
                              style: _createTextStyle(
                                fontSize: 10,
                                font: regularFont,
                              ),
                            ),
                          ),
                        ),
                        pw.Container(height: 20), // Empty cell for product name
                        pw.Container(height: 20), // Empty cell for unit price
                        pw.Container(height: 20), // Empty cell for total
                      ],
                    );
                  }),
                ],
              ),
              
              pw.SizedBox(height: 5),
              
              // Total line
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColors.black,
              ),
              
              pw.SizedBox(height: 5),
              
              // Total Amount - BLANK
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TỔNG TIỀN: ____________________ VNĐ',
                  style: _createTextStyle(
                    fontSize: 12,
                    font: boldFont, // Sử dụng boldFont cho tổng tiền
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }

  pw.TextStyle _createTextStyle({
    required double fontSize,
    pw.Font? font,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      font: font,
    );
  }
}
