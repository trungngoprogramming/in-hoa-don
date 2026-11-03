/* Dữ liệu chỉ nằm trên máy: lịch sử hóa đơn trong IndexedDB, bản nháp form trong localStorage. */
'use strict';

const Store = (() => {
  const DB_NAME = 'hoa-don';
  const DB_VERSION = 1;
  const INVOICES = 'invoices';
  const DRAFT_KEY = 'hoa-don.draft';

  let dbPromise = null;

  function openDb() {
    if (!dbPromise) {
      dbPromise = new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);
        request.onupgradeneeded = () => {
          // Mỗi bản ghi: { id, date: "2026-11-03", customerName, items, createdAt }
          const store = request.result.createObjectStore(INVOICES, { keyPath: 'id', autoIncrement: true });
          store.createIndex('date', 'date');
        };
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      dbPromise.catch(() => {
        dbPromise = null;
      });
    }
    return dbPromise;
  }

  async function run(mode, action) {
    const db = await openDb();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(INVOICES, mode);
      const request = action(tx.objectStore(INVOICES));
      tx.oncomplete = () => resolve(request.result);
      tx.onerror = () => reject(tx.error);
      tx.onabort = () => reject(tx.error);
    });
  }

  const toRecord = (invoice) => ({
    customerName: invoice.customerName,
    items: invoice.items,
    createdAt: invoice.createdAt,
  });

  /** Lưu hóa đơn mới vào ngày tạo; trả về id. */
  function addInvoice(invoice) {
    const record = { ...toRecord(invoice), date: Core.dateKey(new Date(invoice.createdAt)) };
    return run('readwrite', (store) => store.add(record));
  }

  /** Ghi đè hóa đơn đã lưu; hóa đơn vẫn nằm ở ngày cũ trong lịch sử. */
  function updateInvoice(id, date, invoice) {
    return run('readwrite', (store) => store.put({ ...toRecord(invoice), id, date }));
  }

  function deleteInvoice(id) {
    return run('readwrite', (store) => store.delete(id));
  }

  /** Hóa đơn của một ngày, theo thứ tự lưu. */
  function getInvoicesByDate(date) {
    return run('readonly', (store) => store.index('date').getAll(date));
  }

  /** Xin trình duyệt không tự dọn dữ liệu khi máy thiếu dung lượng. */
  async function requestPersistence() {
    if (navigator.storage?.persist && !(await navigator.storage.persisted())) {
      await navigator.storage.persist();
    }
  }

  // Bản nháp chỉ là tiện ích: localStorage bị chặn hoặc đầy thì bỏ qua, không làm hỏng luồng nhập đơn.
  function getDraft() {
    try {
      return { customerName: '', orderText: '', ...JSON.parse(localStorage.getItem(DRAFT_KEY)) };
    } catch {
      return { customerName: '', orderText: '' };
    }
  }

  function saveDraft(draft) {
    try {
      localStorage.setItem(DRAFT_KEY, JSON.stringify(draft));
    } catch {
      /* xem ghi chú ở trên */
    }
  }

  function clearDraft() {
    try {
      localStorage.removeItem(DRAFT_KEY);
    } catch {
      /* xem ghi chú ở trên */
    }
  }

  return {
    addInvoice,
    updateInvoice,
    deleteInvoice,
    getInvoicesByDate,
    requestPersistence,
    getDraft,
    saveDraft,
    clearDraft,
  };
})();
