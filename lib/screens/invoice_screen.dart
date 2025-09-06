import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../models/app_state.dart';
import '../models/invoice_model.dart';
import '../utils/order_parser.dart';

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
    
    // Sử dụng font mặc định hoặc fallback font cho Android
    pw.Font? font;
    try {
      font = await PdfGoogleFonts.robotoRegular();
    } catch (e) {
      // Fallback to default font nếu không thể tải Google Font
      print('Cannot load Google Font, using default font: $e');
      font = null;
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
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 5),
              
              // Company Info
              pw.Text(
                'ĐC: 139/1 Tôn Đản, TP. Đà Nẵng * ĐT: 0905070472 - 0344678772',
                style: _createTextStyle(
                fontSize: 12,
                font: font,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 3),
              
              pw.Text(
                'Chuyên bán: BÁNH ĐẬU XANH, BÁNH DỪA NƯỚNG, KHÔ MÈ, MÈ XỬNG, KẸO ĐẬU,',
                style: _createTextStyle(
                  fontSize: 10,
                  font: font,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'KẸO DỒI, BẮP, NUI, ME, CỐM, THÈO LÈO, CHUỐI SẤY, BÁNH THÁNH, BÁNH MEN...',
                style: _createTextStyle(
                  fontSize: 10,
                  font: font,
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
                      font: font,
                    ),
                  ),
                  pw.Text(
                    'Ngày: ${_formatDate(invoice.createdAt)}',
                    style: _createTextStyle(
                      fontSize: 10,
                      font: font,
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
                        child: pw.Center(
                          child: pw.Text(
                            'TT',
                            style: _createTextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                          child: pw.Text(
                            'SL x TÊN HÀNG',
                            style: _createTextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                          child: pw.Text(
                            'ĐƠN GIÁ',
                            style: _createTextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                        ),
                      ),
                      pw.Container(
                        height: 25,
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Center(
                          child: pw.Text(
                            'THÀNH TIỀN',
                            style: _createTextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
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
                                  fontSize: 7,
                                  font: font,
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
                              style: pw.TextStyle(fontSize: 7, font: font),
                            ),
                          ),
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Center(
                              child: pw.Text(
                                '${_formatNumber(item.price.toInt())} VNĐ',
                                style: _createTextStyle(
                                  fontSize: 7,
                                  font: font,
                                ),
                              ),
                            ),
                          ),
                          pw.Container(
                            height: 20,
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Center(
                              child: pw.Text(
                                '${_formatNumber(item.total.toInt())} VNĐ',
                                style: _createTextStyle(
                                  fontSize: 7,
                                  font: font,
                                ),
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
                                  fontSize: 7,
                                  font: font,
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
                  'TỔNG TIỀN: ${_formatNumber(invoice.totalAmount.toInt())} VNĐ',
                  style: _createTextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
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
    pw.FontWeight? fontWeight,
    pw.Font? font,
  }) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      font: font,
    );
  }

  void _printInvoice(BuildContext context, InvoiceModel invoice) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await _generatePdf(invoice),
    );
  }
}
