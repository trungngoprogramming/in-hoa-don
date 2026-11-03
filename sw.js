/* Lưu toàn bộ app vào máy ở lần mở đầu tiên; các lần sau chạy hoàn toàn không cần mạng.
   Sửa bất kỳ file nào trong ASSETS thì tăng VERSION để máy người dùng tải bản mới. */
const VERSION = 1;
const CACHE_PREFIX = 'hoa-don-';
const CACHE = `${CACHE_PREFIX}v${VERSION}`;
const ASSETS = [
  './index.html',
  './manifest.webmanifest',
  './css/app.css',
  './js/core.js',
  './js/store.js',
  './js/invoice.js',
  './js/app.js',
  './vendor/jspdf.umd.min.js',
  './fonts/NotoSans-Regular.ttf',
  './fonts/Carlito-Bold.ttf',
  './icons/favicon.png',
  './icons/apple-touch-icon.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      // cache: 'reload' để không lấy nhầm file cũ trong bộ nhớ đệm HTTP khi cập nhật
      .then((cache) => cache.addAll(ASSETS.map((url) => new Request(url, { cache: 'reload' }))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;
  // Mở app (kể cả có #/... hay ?source=...) luôn trả về index.html đã lưu.
  const appRoot = new URL('./', self.location).pathname;
  const isAppPage = request.mode === 'navigate' && (url.pathname === appRoot || url.pathname === `${appRoot}index.html`);
  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const cached = isAppPage ? await cache.match('./index.html') : await cache.match(request, { ignoreSearch: true });
      return cached || fetch(request);
    }),
  );
});
