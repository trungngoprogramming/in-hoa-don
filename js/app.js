/* Điều khiển giao diện: chuyển màn hình, nhập đơn, xem lại, in/chia sẻ hóa đơn và lịch sử. */
'use strict';

(() => {
  const $ = (selector) => document.querySelector(selector);

  // iPhone/iPad (iPadOS tự báo là Mac nhưng có màn hình cảm ứng). Trên iOS 27, lệnh in của trình duyệt
  // không chạy khi mở app từ màn hình chính, nên trên iOS luôn in bằng file PDF qua bảng chia sẻ.
  const IS_IOS =
    /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  // ---------- Trạng thái phiên: giữ lại khi trang bị tải lại giữa chừng ----------

  const SESSION_KEY = 'hoa-don.session';
  const state = (() => {
    // form: nội dung form đơn hàng; invoice: hóa đơn đang xem/in; editTarget: hóa đơn cũ sẽ bị ghi đè khi in.
    const initial = { form: null, invoice: null, editTarget: null, historyDate: Core.dateKey(new Date()) };
    try {
      return { ...initial, ...JSON.parse(sessionStorage.getItem(SESSION_KEY)) };
    } catch {
      return initial;
    }
  })();

  function saveSession() {
    try {
      sessionStorage.setItem(SESSION_KEY, JSON.stringify(state));
    } catch {
      /* chỉ mất khả năng khôi phục khi tải lại trang */
    }
  }

  // ---------- Chuyển màn hình ----------

  const ROUTES = {
    '#/': { view: 'view-home' },
    '#/order': { view: 'view-order', enter: enterOrder },
    '#/review': { view: 'view-review', enter: enterReview, requires: () => state.invoice },
    '#/invoice': { view: 'view-invoice', enter: () => enterInvoice(state.invoice), requires: () => state.invoice },
    '#/blank': { view: 'view-invoice', enter: () => enterInvoice(null) },
    '#/history': { view: 'view-history', enter: enterHistory },
  };

  function render() {
    let route = ROUTES[location.hash] ? location.hash : '#/';
    if (ROUTES[route].requires && !ROUTES[route].requires()) route = '#/';
    if (route !== location.hash) history.replaceState({ depth: history.state?.depth ?? 0 }, '', route);

    const { view, enter } = ROUTES[route];
    for (const section of document.querySelectorAll('.view')) section.hidden = section.id !== view;
    window.scrollTo(0, 0);
    enter?.();
  }

  function navigate(route, { replace = false } = {}) {
    const depth = (history.state?.depth ?? 0) + (replace ? 0 : 1);
    history[replace ? 'replaceState' : 'pushState']({ depth }, '', route);
    render();
  }

  // Lùi về màn hình trước trong app; mở thẳng vào màn hình con (vd. sau khi tải lại) thì về màn hình cha.
  function goBack(fallback) {
    if ((history.state?.depth ?? 0) > 0) history.back();
    else navigate(fallback, { replace: true });
  }

  window.addEventListener('popstate', render);

  const ACTIONS = {
    'new-order': () => {
      state.form = { ...Store.getDraft(), editTarget: null };
      saveSession();
      navigate('#/order');
    },
    'open-history': () => {
      state.historyDate = Core.dateKey(new Date());
      saveSession();
      navigate('#/history');
    },
    'blank-invoice': () => navigate('#/blank'),
    'save-and-print': saveAndPrint,
    print: printInvoice,
    share: sharePdf,
  };

  document.addEventListener('click', (event) => {
    const back = event.target.closest('[data-back]');
    if (back) {
      goBack(back.dataset.back);
      return;
    }
    const button = event.target.closest('[data-action]');
    if (button && !button.disabled) ACTIONS[button.dataset.action]();
  });

  // ---------- Nhập đơn hàng ----------

  const orderForm = $('#order-form');
  const nameInput = $('#customer-name');
  const orderInput = $('#order-text');

  function enterOrder() {
    if (!state.form) {
      state.form = { ...Store.getDraft(), editTarget: null };
      saveSession();
    }
    nameInput.value = state.form.customerName;
    orderInput.value = state.form.orderText;
    setFieldError(nameInput, '');
    setFieldError(orderInput, '');
  }

  function setFieldError(input, message) {
    const field = input.closest('.field');
    field.classList.toggle('invalid', Boolean(message));
    field.querySelector('.field-error').textContent = message;
    input.setAttribute('aria-invalid', String(Boolean(message)));
    return !message;
  }

  orderForm.addEventListener('input', (event) => {
    if (event.target.value.trim()) setFieldError(event.target, '');
    state.form.customerName = nameInput.value;
    state.form.orderText = orderInput.value;
    saveSession();
    // Nháp chỉ dành cho đơn mới: sửa hóa đơn cũ không ghi đè đơn đang nhập dở.
    if (!state.form.editTarget) Store.saveDraft({ customerName: nameInput.value, orderText: orderInput.value });
  });

  // Phím "tiếp" trên bàn phím điện thoại chuyển xuống ô đơn hàng thay vì gửi form.
  nameInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' && !event.isComposing) {
      event.preventDefault();
      orderInput.focus();
    }
  });

  orderForm.addEventListener('submit', (event) => {
    event.preventDefault();
    const customerName = nameInput.value.trim().normalize('NFC');
    const orderText = orderInput.value.trim();
    const nameValid = setFieldError(nameInput, customerName ? '' : 'Vui lòng nhập tên khách hàng');
    const orderValid = setFieldError(orderInput, orderText ? '' : 'Vui lòng nhập thông tin đơn hàng');
    if (!nameValid || !orderValid) return;

    const items = Core.parseOrderText(orderText);
    if (!items.length) {
      snackbar('Không thể parse đơn hàng. Vui lòng kiểm tra định dạng.', 'error');
      return;
    }
    state.invoice = { customerName, items, createdAt: new Date().toISOString() };
    state.editTarget = state.form.editTarget;
    if (!state.editTarget) Store.clearDraft();
    saveSession();
    navigate('#/review');
  });

  // ---------- Xem lại đơn hàng ----------

  function enterReview() {
    const { customerName, items } = state.invoice;
    $('#review-customer').textContent = customerName || 'Khách hàng không tên';
    $('#review-items').replaceChildren(
      ...items.map((item, index) => {
        const row = document.createElement('tr');
        const cells = [
          [index + 1, ''],
          [item.quantity, ''],
          [item.name, ''],
          [Core.formatMoney(item.price), 'num'],
          [Core.formatMoney(item.total), 'num amount'],
        ];
        for (const [value, className] of cells) row.append(el('td', className, String(value)));
        return row;
      }),
    );
    $('#review-total').textContent = Core.formatMoney(Core.totalOf(items));
  }

  let saving = false;

  // Lưu (hoặc cập nhật) vào lịch sử rồi sang màn hình in, như bản app.
  async function saveAndPrint() {
    if (saving) return;
    saving = true;
    try {
      if (state.editTarget) {
        await Store.updateInvoice(state.editTarget.id, state.editTarget.date, state.invoice);
        snackbar('Hóa đơn đã được cập nhật', 'success');
      } else {
        await Store.addInvoice(state.invoice);
        snackbar('Hóa đơn đã được lưu vào lịch sử', 'success');
        Store.requestPersistence().catch(() => {});
      }
    } catch (error) {
      snackbar(`Lỗi khi lưu hóa đơn: ${errorMessage(error)}`, 'error');
    } finally {
      saving = false;
    }
    navigate('#/invoice');
  }

  // ---------- Hóa đơn: xem trước, in, chia sẻ ----------

  const invoicePages = $('#invoice-pages');
  const invoiceStatus = $('#invoice-status');
  const invoiceButtons = document.querySelectorAll('#view-invoice [data-action="print"], #view-invoice [data-action="share"]');
  let invoiceJob = 0;
  let prepared = null; // { title, pages, file } của hóa đơn đang hiển thị

  $('#invoice-hint').hidden = !IS_IOS;
  $('#share-button').hidden = IS_IOS; // trên iOS nút In đã mở bảng chia sẻ

  function enterInvoice(invoice) {
    const job = ++invoiceJob;
    prepared = null;
    $('#invoice-title').textContent = invoice ? 'Hóa Đơn' : 'Hóa Đơn Trống';
    invoicePages.replaceChildren();
    setInvoiceStatus('Đang chuẩn bị hóa đơn…');
    for (const button of invoiceButtons) button.disabled = true;

    InvoiceDoc.build(invoice).then(
      (result) => {
        if (job !== invoiceJob) return;
        prepared = result;
        invoicePages.replaceChildren(...result.pages);
        setInvoiceStatus('');
        for (const button of invoiceButtons) button.disabled = false;
      },
      (error) => {
        if (job === invoiceJob) setInvoiceStatus(`Không tạo được hóa đơn: ${errorMessage(error)}`, true);
      },
    );
  }

  function setInvoiceStatus(message, isError = false) {
    invoiceStatus.textContent = message;
    invoiceStatus.classList.toggle('error', isError);
  }

  function printInvoice() {
    if (IS_IOS) {
      sharePdf();
      return;
    }
    // Tên tài liệu là tên file gợi ý khi chọn "Lưu dạng PDF" trong hộp thoại in.
    const previousTitle = document.title;
    document.title = prepared.file.name.replace(/\.pdf$/, '');
    window.addEventListener('afterprint', () => (document.title = previousTitle), { once: true });
    window.print();
  }

  // Bảng chia sẻ của máy: In (AirPrint), Lưu vào Tệp, Zalo, app của hãng máy in… Không có thì tải file về.
  // Gọi navigator.share ngay trong lần bấm (file đã dựng sẵn), vì iOS chặn chia sẻ nếu phải chờ.
  async function sharePdf() {
    const { file } = prepared;
    if (navigator.canShare?.({ files: [file] })) {
      try {
        await navigator.share({ files: [file] });
        return;
      } catch (error) {
        if (error.name === 'AbortError') return; // người dùng đóng bảng chia sẻ
      }
    }
    downloadFile(file);
  }

  function downloadFile(file) {
    const url = URL.createObjectURL(file);
    const link = Object.assign(document.createElement('a'), { href: url, download: file.name });
    document.body.append(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 60_000);
  }

  // ---------- Lịch sử ----------

  const historyList = $('#history-list');
  const dateInput = $('#history-date');
  let historyJob = 0;

  async function enterHistory() {
    const job = ++historyJob;
    dateInput.max = Core.dateKey(new Date());
    dateInput.value = state.historyDate;
    $('#history-date-label').textContent = Core.formatDate(Core.keyToDate(state.historyDate));
    try {
      const invoices = await Store.getInvoicesByDate(state.historyDate);
      if (job !== historyJob) return;
      historyList.replaceChildren(...(invoices.length ? invoices.map(historyCard) : [emptyHistory()]));
    } catch (error) {
      if (job !== historyJob) return;
      historyList.replaceChildren();
      snackbar(`Lỗi khi tải dữ liệu: ${errorMessage(error)}`, 'error');
    }
  }

  dateInput.addEventListener('change', () => {
    if (!dateInput.value) return; // nút "Xóa" của bộ chọn ngày
    state.historyDate = dateInput.value;
    saveSession();
    enterHistory();
  });

  // Máy tính: bấm vào đâu trên nút cũng mở lịch (điện thoại tự mở bộ chọn ngày khi chạm).
  dateInput.addEventListener('click', () => {
    if (!matchMedia('(pointer: fine)').matches) return;
    try {
      dateInput.showPicker?.();
    } catch {
      /* trình duyệt không cho mở bằng lệnh: người dùng vẫn bấm được vào ô ngày */
    }
  });

  function historyCard(invoice) {
    const card = el('article', 'card history-item');
    const actions = el('div', 'history-actions');
    actions.append(
      chip('Sửa', 'i-edit', 'chip-edit', () => editInvoice(invoice)),
      chip('In lại', 'i-print', 'chip-print', () => reprintInvoice(invoice)),
      chip('Xóa', 'i-delete', 'chip-delete', () => deleteInvoice(invoice)),
    );
    card.append(
      el('h3', '', invoice.customerName || 'Khách hàng không tên'),
      el('p', 'muted', `Số lượng sản phẩm: ${invoice.items.length}`),
      el('p', 'amount', `Tổng tiền: ${Core.formatMoney(Core.totalOf(invoice.items))} VND`),
      el('p', 'muted', `Thời gian: ${Core.formatTime(new Date(invoice.createdAt))}`),
      actions,
    );
    return card;
  }

  function emptyHistory() {
    const box = el('div', 'empty-state');
    box.append(icon('i-receipt'), el('p', '', 'Không có hóa đơn nào trong ngày này'));
    return box;
  }

  function editInvoice(invoice) {
    state.form = {
      customerName: invoice.customerName,
      orderText: Core.invoiceToOrderText(invoice),
      editTarget: { id: invoice.id, date: invoice.date },
    };
    saveSession();
    navigate('#/order');
  }

  function reprintInvoice(invoice) {
    state.invoice = { customerName: invoice.customerName, items: invoice.items, createdAt: invoice.createdAt };
    saveSession();
    navigate('#/invoice');
  }

  async function deleteInvoice(invoice) {
    if (!(await confirmDelete())) return;
    try {
      await Store.deleteInvoice(invoice.id);
    } catch (error) {
      snackbar(`Lỗi khi xóa hóa đơn: ${errorMessage(error)}`, 'error');
    }
    enterHistory();
  }

  const confirmDialog = $('#confirm-delete');

  function confirmDelete() {
    if (typeof confirmDialog.showModal !== 'function') {
      return Promise.resolve(window.confirm('Bạn có chắc chắn muốn xóa hóa đơn này?'));
    }
    return new Promise((resolve) => {
      confirmDialog.returnValue = '';
      confirmDialog.addEventListener('close', () => resolve(confirmDialog.returnValue === 'ok'), { once: true });
      confirmDialog.showModal();
    });
  }

  // ---------- Tiện ích giao diện ----------

  const snackbarEl = $('#snackbar');
  let snackbarTimer = 0;

  function snackbar(message, tone = '') {
    snackbarEl.textContent = message;
    snackbarEl.className = `snackbar show ${tone}`;
    clearTimeout(snackbarTimer);
    snackbarTimer = setTimeout(() => snackbarEl.classList.remove('show'), 3500);
  }

  function errorMessage(error) {
    return error?.message || String(error);
  }

  function el(tag, className = '', text = '') {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
  }

  function icon(id) {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('class', 'icon');
    svg.setAttribute('aria-hidden', 'true');
    const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
    use.setAttribute('href', `#${id}`);
    svg.append(use);
    return svg;
  }

  function chip(label, iconId, className, onClick) {
    const button = el('button', `chip ${className}`);
    button.type = 'button';
    button.append(icon(iconId), label);
    button.addEventListener('click', onClick);
    return button;
  }

  // ---------- Khởi động ----------

  if (!history.state) history.replaceState({ depth: 0 }, '', location.hash || '#/');
  render();

  // Lưu toàn bộ app vào máy để lần sau mở không cần mạng.
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('sw.js').catch((error) => console.warn('Không cài được bản offline:', error));
    });
  }
})();
