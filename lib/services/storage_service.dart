import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/invoice_model.dart';

class StorageService {
  static const String _invoicePrefix = 'invoices_';
  static const String _customerNameKey = 'savedCustomerName';
  static const String _orderInfoKey = 'savedOrderInfo';

  // Lưu hóa đơn
  static Future<void> saveInvoice(InvoiceModel invoice) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(invoice.createdAt);
    final key = '$_invoicePrefix$dateKey';
    
    final invoicesJson = prefs.getStringList(key) ?? [];
    invoicesJson.add(jsonEncode(invoice.toJson()));
    
    await prefs.setStringList(key, invoicesJson);
  }

  // Lấy danh sách hóa đơn theo ngày
  static Future<List<InvoiceModel>> getInvoicesByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final key = '$_invoicePrefix$dateKey';
    
    final invoicesJson = prefs.getStringList(key) ?? [];
    
    return invoicesJson
        .map((json) => InvoiceModel.fromJson(jsonDecode(json)))
        .toList();
  }

  // Xóa hóa đơn
  static Future<void> deleteInvoice(DateTime date, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final key = '$_invoicePrefix$dateKey';
    
    final invoicesJson = prefs.getStringList(key) ?? [];
    
    if (index < invoicesJson.length) {
      invoicesJson.removeAt(index);
      await prefs.setStringList(key, invoicesJson);
    }
  }

  // Cập nhật hóa đơn
  static Future<void> updateInvoice(DateTime date, int index, InvoiceModel updatedInvoice) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final key = '$_invoicePrefix$dateKey';
    
    final invoicesJson = prefs.getStringList(key) ?? [];
    
    if (index < invoicesJson.length) {
      // Cập nhật hóa đơn tại index cụ thể
      invoicesJson[index] = jsonEncode(updatedInvoice.toJson());
      await prefs.setStringList(key, invoicesJson);
    }
  }

  // Lưu thông tin form tạm thời
  static Future<void> saveFormData(String customerName, String orderInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customerNameKey, customerName);
    await prefs.setString(_orderInfoKey, orderInfo);
  }

  // Lấy thông tin form tạm thời
  static Future<Map<String, String>> getFormData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'customerName': prefs.getString(_customerNameKey) ?? '',
      'orderInfo': prefs.getString(_orderInfoKey) ?? '',
    };
  }

  // Xóa thông tin form tạm thời
  static Future<void> clearFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customerNameKey);
    await prefs.remove(_orderInfoKey);
  }

  // Lấy tất cả ngày có hóa đơn
  static Future<List<DateTime>> getAllInvoiceDates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_invoicePrefix));
    
    final dates = <DateTime>[];
    for (final key in keys) {
      final dateString = key.replaceFirst(_invoicePrefix, '');
      try {
        final date = DateFormat('yyyy-MM-dd').parse(dateString);
        dates.add(date);
      } catch (e) {
        // Bỏ qua key không hợp lệ
      }
    }
    
    dates.sort((a, b) => b.compareTo(a)); // Sắp xếp giảm dần
    return dates;
  }
}
