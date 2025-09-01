import '../models/invoice_model.dart';
import 'package:intl/intl.dart';

class OrderParser {
  static List<InvoiceItem> parseOrderText(String orderText) {
    final lines = orderText.split('\n');
    final items = <InvoiceItem>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Regex pattern để match: "số_lượng tên_sản_phẩm x đơn_giá"
      final regex = RegExp(r'^(\d+)\s+(.+?)\s+x\s+(\d+(?:\.\d+)?)$');
      final match = regex.firstMatch(trimmedLine);

      if (match != null) {
        final quantity = int.parse(match.group(1)!);
        final name = match.group(2)!.trim();
        final price = double.parse(match.group(3)!);
        
        // Chuyển đổi đơn giá từ nghìn đồng sang đồng
        final priceInVND = price * 1000;
        final total = quantity * priceInVND;

        items.add(InvoiceItem(
          name: name,
          quantity: quantity,
          price: priceInVND,
          total: total,
        ));
      }
    }

    return items;
  }

  static String formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price.toInt())} VNĐ';
  }

  static String formatTotal(double total) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(total.toInt())} VNĐ';
  }
}
