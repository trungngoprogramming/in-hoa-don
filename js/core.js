/* Logic thuần (không đụng giao diện): đọc đơn hàng, tính tiền, định dạng số và ngày. */
'use strict';

const Core = (() => {
  // "số_lượng tên_sản_phẩm x đơn_giá", khoảng trắng linh hoạt: "20 leo x1.2", "20 leo x 1.2", "20 leo  x  1.2"
  const ORDER_LINE = /^(\d+)\s+(.+?)\s*x\s*(\d+(?:\.\d+)?)$/;

  /** Đọc từng dòng đơn hàng; dòng sai định dạng bị bỏ qua. Đơn giá nhập theo nghìn đồng (1.2 = 1.200đ). */
  function parseOrderText(text) {
    const items = [];
    for (const line of String(text).split('\n')) {
      const match = ORDER_LINE.exec(line.trim());
      if (!match) continue;
      const quantity = Number.parseInt(match[1], 10);
      // Làm tròn về đồng: số thực dấu phẩy động cho 32.3 * 1000 = 32299.999…
      const price = Math.round(Number.parseFloat(match[3]) * 1000);
      items.push({ name: match[2].trim().normalize('NFC'), quantity, price, total: quantity * price });
    }
    return items;
  }

  /** Chiều ngược của parseOrderText, dùng khi sửa hóa đơn đã lưu: 1200đ → "x1.2". */
  function invoiceToOrderText(invoice) {
    return invoice.items.map((item) => `${item.quantity} ${item.name} x${item.price / 1000}`).join('\n');
  }

  function totalOf(items) {
    return items.reduce((sum, item) => sum + item.total, 0);
  }

  /** 1234567 → "1.234.567" (chấm ngăn cách hàng nghìn, bỏ phần lẻ). */
  function formatMoney(value) {
    return String(Math.trunc(value)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  }

  const pad2 = (n) => String(n).padStart(2, '0');

  /** Ngày theo giờ máy dạng "2026-11-03": khóa lịch sử và giá trị của input type=date. */
  function dateKey(date) {
    return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
  }

  function keyToDate(key) {
    const [year, month, day] = key.split('-').map(Number);
    return new Date(year, month - 1, day);
  }

  function formatDate(date) {
    return `${pad2(date.getDate())}/${pad2(date.getMonth() + 1)}/${date.getFullYear()}`;
  }

  function formatTime(date) {
    return `${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
  }

  return { parseOrderText, invoiceToOrderText, totalOf, formatMoney, dateKey, keyToDate, formatDate, formatTime };
})();
