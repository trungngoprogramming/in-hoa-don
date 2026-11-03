/* Mẫu hóa đơn A5 (giữ đúng mẫu của bản app). Dàn trang một lần, đơn vị pt, rồi vẽ ra hai nơi:
   - SVG: xem trước trên màn hình và in thẳng từ trình duyệt (Android, máy tính);
   - PDF (jsPDF): in/chia sẻ trên iPhone, lưu file.
   Vì dùng chung một bản dàn trang và cùng font nên bản in ở mọi máy giống hệt nhau. */
'use strict';

const InvoiceDoc = (() => {
  const PAGE_W = 419.53; // A5: 148 × 210 mm
  const PAGE_H = 595.28;
  const MARGIN = 15;
  const CONTENT_W = PAGE_W - MARGIN * 2;
  const ROWS_PER_PAGE = 20;
  const HEADER_ROW_H = 25;
  const ROW_H = 20;
  const CELL_PAD = 12;
  const HEADERS = ['TT', 'SL x TÊN HÀNG', 'ĐƠN GIÁ', 'THÀNH TIỀN'];

  // Ranh giới cột: TT rộng 25pt, phần còn lại chia 4:2:2.
  const COLUMN_X = (() => {
    const unit = (CONTENT_W - 25) / 8;
    const xs = [MARGIN, MARGIN + 25];
    for (const units of [4, 2, 2]) xs.push(xs[xs.length - 1] + unit * units);
    return xs;
  })();

  // ascent/descent (đơn vị em) lấy từ bảng hhea của file font, giống cách thư viện pdf của Flutter canh dòng.
  const FONTS = {
    regular: {
      url: 'fonts/NotoSans-Regular.ttf',
      family: 'NotoSans',
      style: 'normal',
      css: '400 10px "HD Noto Sans"',
      ascent: 1069 / 1000,
      descent: 293 / 1000,
    },
    bold: {
      url: 'fonts/Carlito-Bold.ttf',
      family: 'Carlito',
      style: 'bold',
      css: '700 10px "HD Carlito"',
      ascent: 1950 / 2048,
      descent: 550 / 2048,
    },
  };

  const SHOP = {
    name: 'BÁNH KẸO HÙNG CHÍNH',
    address: 'ĐC: 139/1 Tôn Đản, TP. Đà Nẵng * ĐT: 0905.070.472 - 0344.678.772',
    products: [
      'Chuyên bán: BÁNH ĐẬU XANH, BÁNH DỪA NƯỚNG, KHÔ MÈ, MÈ XỬNG, KẸO ĐẬU,',
      'KẸO DỒI, BẮP, NUI, ME, CỐM, THÈO LÈO, CHUỐI SẤY, BÁNH THÁNH, BÁNH MEN...',
    ],
  };

  const lineHeight = (font, size) => (FONTS[font].ascent + FONTS[font].descent) * size;

  /** invoice = null → hóa đơn trống để ghi tay. Trả về danh sách trang, mỗi trang là danh sách lệnh vẽ. */
  function layout(invoice, measure) {
    const items = invoice ? invoice.items : [];
    const pageCount = Math.max(1, Math.ceil(items.length / ROWS_PER_PAGE));
    return Array.from({ length: pageCount }, (_, page) => layoutPage({ invoice, items, page, pageCount, measure }));
  }

  function layoutPage({ invoice, items, page, pageCount, measure }) {
    const ops = [];
    const left = MARGIN;
    const right = PAGE_W - MARGIN;

    // Chữ một dòng, canh giữa theo chiều dọc trong [top, top + height]; dài quá maxWidth thì thu nhỏ cỡ chữ.
    const text = (value, { font, size, x, align = 'left', top, height = lineHeight(font, size), maxWidth = CONTENT_W }) => {
      const width = measure(value, font, size);
      const fitted = width > maxWidth ? (size * maxWidth) / width : size;
      const y = top + (height - lineHeight(font, fitted)) / 2 + FONTS[font].ascent * fitted;
      ops.push({ kind: 'text', text: value, font, size: fitted, x, y, align });
    };

    let y = MARGIN;
    const centeredLine = (value, font, size) => {
      text(value, { font, size, x: PAGE_W / 2, align: 'center', top: y });
      y += lineHeight(font, size);
    };

    centeredLine(SHOP.name, 'bold', 20);
    y += 5;
    centeredLine(SHOP.address, 'regular', 12);
    y += 3;
    for (const line of SHOP.products) centeredLine(line, 'regular', 10);
    y += 10;

    const dateText = invoice ? `Ngày: ${Core.formatDate(new Date(invoice.createdAt))}` : 'Ngày: _______________';
    const customerText = invoice ? `Khách hàng: ${invoice.customerName}` : 'Khách hàng: _______________________';
    const dateWidth = measure(dateText, 'regular', 10);
    text(customerText, { font: 'regular', size: 10, x: left, top: y, maxWidth: CONTENT_W - dateWidth - 12 });
    text(dateText, { font: 'regular', size: 10, x: right, align: 'right', top: y });
    y += lineHeight('regular', 10) + 10;

    const [x0, x1, x2, x3, x4] = COLUMN_X;
    const tableTop = y;
    const bodyTop = tableTop + HEADER_ROW_H;
    const tableBottom = bodyTop + ROWS_PER_PAGE * ROW_H;

    ops.push({ kind: 'rect', x: x0, y: tableTop, w: x4 - x0, h: HEADER_ROW_H, fill: '#e0e0e0' });
    HEADERS.forEach((label, c) => {
      const [from, to] = [COLUMN_X[c], COLUMN_X[c + 1]];
      text(label, { font: 'bold', size: 10, x: (from + to) / 2, align: 'center', top: tableTop, height: HEADER_ROW_H, maxWidth: to - from - 6 });
    });

    for (let row = 0; row < ROWS_PER_PAGE; row++) {
      const index = page * ROWS_PER_PAGE + row;
      const cell = { font: 'regular', size: 10, top: bodyTop + row * ROW_H, height: ROW_H };
      text(String(index + 1), { ...cell, x: (x0 + x1) / 2, align: 'center', maxWidth: x1 - x0 - 4 });
      const item = items[index];
      if (!item) continue;
      text(`${item.quantity} ${item.name}`, { ...cell, x: x1 + CELL_PAD, maxWidth: x2 - x1 - CELL_PAD - 2 });
      text(Core.formatMoney(item.price), { ...cell, x: x3 - CELL_PAD, align: 'right', maxWidth: x3 - x2 - CELL_PAD - 2 });
      text(Core.formatMoney(item.total), { ...cell, x: x4 - CELL_PAD, align: 'right', maxWidth: x4 - x3 - CELL_PAD - 2 });
    }

    for (const x of COLUMN_X) ops.push({ kind: 'line', x1: x, y1: tableTop, x2: x, y2: tableBottom });
    for (const lineY of [tableTop, ...Array.from({ length: ROWS_PER_PAGE + 1 }, (_, r) => bodyTop + r * ROW_H)]) {
      ops.push({ kind: 'line', x1: x0, y1: lineY, x2: x4, y2: lineY });
    }

    y = tableBottom + 5;
    ops.push({ kind: 'rect', x: left, y, w: CONTENT_W, h: 1, fill: '#000000' });
    y += 1 + 5;
    const footer = { top: y, height: lineHeight('bold', 12) };
    if (pageCount > 1) {
      text(`Trang ${page + 1}/${pageCount}`, { font: 'regular', size: 10, x: left, ...footer });
    }
    if (page === pageCount - 1) {
      const total = invoice ? `TỔNG TIỀN: ${Core.formatMoney(Core.totalOf(invoice.items))}` : 'TỔNG TIỀN: ____________________';
      text(total, { font: 'bold', size: 12, x: right, align: 'right', ...footer, maxWidth: CONTENT_W - 80 });
    }
    return ops;
  }

  const SVG_NS = 'http://www.w3.org/2000/svg';
  const ANCHOR = { left: 'start', center: 'middle', right: 'end' };
  const round = (n) => Math.round(n * 1000) / 1000;

  function renderSvg(ops, index, count) {
    const svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('viewBox', `0 0 ${PAGE_W} ${PAGE_H}`);
    svg.setAttribute('class', 'invoice-page');
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', count > 1 ? `Hóa đơn, trang ${index + 1}/${count}` : 'Hóa đơn');
    for (const op of ops) {
      const node = document.createElementNS(SVG_NS, op.kind);
      const attrs =
        op.kind === 'rect'
          ? { x: op.x, y: op.y, width: op.w, height: op.h, fill: op.fill }
          : op.kind === 'line'
            ? { x1: op.x1, y1: op.y1, x2: op.x2, y2: op.y2 }
            : { x: op.x, y: op.y, 'font-size': op.size, class: `inv-${op.font}`, 'text-anchor': ANCHOR[op.align] };
      for (const [name, value] of Object.entries(attrs)) {
        node.setAttribute(name, typeof value === 'number' ? round(value) : value);
      }
      if (op.kind === 'text') node.textContent = op.text;
      svg.append(node);
    }
    return svg;
  }

  function drawPdf(doc, pages) {
    pages.forEach((ops, index) => {
      if (index > 0) doc.addPage('a5', 'portrait');
      doc.setDrawColor(0, 0, 0);
      doc.setLineWidth(1);
      doc.setLineCap('square');
      doc.setTextColor(0, 0, 0);
      for (const op of ops) {
        if (op.kind === 'rect') {
          doc.setFillColor(op.fill);
          doc.rect(op.x, op.y, op.w, op.h, 'F');
        } else if (op.kind === 'line') {
          doc.line(op.x1, op.y1, op.x2, op.y2);
        } else {
          doc.setFont(FONTS[op.font].family, FONTS[op.font].style);
          doc.setFontSize(op.size);
          doc.text(op.text, op.x, op.y, { align: op.align });
        }
      }
    });
  }

  // Font cho PDF đọc dạng nhị phân một lần; font cho SVG do trình duyệt nạp qua @font-face trong app.css.
  let fontData = null;

  function loadFontData() {
    if (!fontData) {
      fontData = Promise.all(
        Object.entries(FONTS).map(async ([key, font]) => {
          const response = await fetch(font.url);
          if (!response.ok) throw new Error(`không tải được ${font.url}`);
          return [key, toBinaryString(await response.arrayBuffer())];
        }),
      ).then(Object.fromEntries);
      fontData.catch(() => {
        fontData = null;
      });
    }
    return fontData;
  }

  function toBinaryString(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.length; i += 0x8000) {
      binary += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
    }
    return binary;
  }

  function loadCssFonts() {
    return document.fonts ? Promise.all(Object.values(FONTS).map((font) => document.fonts.load(font.css))) : null;
  }

  function fileName(invoice) {
    if (!invoice) return 'hoa-don-trong.pdf';
    const slug = invoice.customerName
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[đĐ]/g, 'd')
      .replace(/[^a-z0-9]+/gi, '-')
      .replace(/^-+|-+$/g, '')
      .toLowerCase();
    return `hoa-don-${slug || 'khach-hang'}-${Core.dateKey(new Date(invoice.createdAt))}.pdf`;
  }

  /** Dựng hóa đơn: trang SVG để xem/in và file PDF để chia sẻ. invoice = null → hóa đơn trống. */
  async function build(invoice) {
    const [fonts] = await Promise.all([loadFontData(), loadCssFonts()]);
    const doc = new window.jspdf.jsPDF({ unit: 'pt', format: 'a5', compress: true });
    for (const [key, font] of Object.entries(FONTS)) {
      const vfsName = font.url.split('/').pop();
      doc.addFileToVFS(vfsName, fonts[key]);
      doc.addFont(vfsName, font.family, font.style);
    }
    const measure = (value, font, size) => {
      doc.setFont(FONTS[font].family, FONTS[font].style);
      doc.setFontSize(size);
      return doc.getTextWidth(value);
    };

    const pages = layout(invoice, measure);
    drawPdf(doc, pages);
    const title = invoice
      ? `Hóa đơn ${invoice.customerName} ${Core.formatDate(new Date(invoice.createdAt))}`
      : 'Hóa đơn trống';
    doc.setProperties({ title, creator: 'In Hóa Đơn - Bánh Kẹo Hùng Chính' });

    return {
      title,
      pages: pages.map((ops, index) => renderSvg(ops, index, pages.length)),
      file: new File([doc.output('blob')], fileName(invoice), { type: 'application/pdf' }),
    };
  }

  return { build };
})();
