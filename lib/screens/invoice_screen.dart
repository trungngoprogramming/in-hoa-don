import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../models/app_state.dart';
import '../models/invoice_model.dart';

class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(appStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa Đơn'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _printInvoice(context, invoice),
            icon: const Icon(Icons.print),
            tooltip: 'In Hóa Đơn',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(invoice),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        maxPageWidth: 700,
      ),
    );
  }

  Future<Uint8List> _generatePdf(InvoiceModel invoice) async {
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
                'ĐC: 139/1 Tôn Đản, TP. Đà Nẵng * ĐT: 0905.070.472 - 0344.678.772',
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
              
              // Customer and Date Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Khách hàng: ${invoice.customerName}',
                    style: _createTextStyle(
                      fontSize: 10,
                      font: regularFont,
                    ),
                  ),
                  pw.Text(
                    'Ngày: ${_formatDate(invoice.createdAt)}',
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
                  // Items rows
                  ...List.generate(20, (index) {
                    if (index < invoice.items.length) {
                      final item = invoice.items[index];
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
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.only(left: 12, top: 2, right: 2, bottom: 2),
                            alignment: pw.Alignment.centerLeft,
                            child: pw.Text(
                              '${item.quantity} ${item.name}',
                              style: pw.TextStyle(fontSize: 10, font: regularFont),
                            ),
                          ),
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.only(left: 2, top: 2, right: 12, bottom: 2),
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              '${_formatNumber(item.price.toInt())}',
                              style: _createTextStyle(
                                fontSize: 10,
                                font: regularFont,
                              ),
                            ),
                          ),
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.only(left: 2, top: 2, right: 12, bottom: 2),
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              '${_formatNumber(item.total.toInt())}',
                              style: _createTextStyle(
                                fontSize: 10,
                                font: regularFont,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Empty rows
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
                          pw.Container(height: 20),
                          pw.Container(height: 20),
                          pw.Container(height: 20),
                        ],
                      );
                    }
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
              
              // Total Amount
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TỔNG TIỀN: ${_formatNumber(invoice.totalAmount.toInt())}',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
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

  void _printInvoice(BuildContext context, InvoiceModel invoice) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await _generatePdf(invoice),
    );
  }

}
