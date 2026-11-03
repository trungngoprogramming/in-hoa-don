# In Hóa Đơn – Bánh Kẹo Hùng Chính

Web app nhập đơn hàng và in hóa đơn A5. Chỉ gồm HTML, CSS, JavaScript tĩnh: không có server xử lý, không cần build, không cần cài app từ App Store/CH Play. Thêm vào màn hình chính điện thoại là dùng như app, sau lần mở đầu tiên chạy được cả khi không có mạng, dữ liệu nằm trên điện thoại.

## Tính năng

- Nhập đơn theo định dạng `số_lượng tên_hàng x đơn_giá`, mỗi dòng một món (vd. `20 leo x 1.2`).
- Xem lại đơn, lưu vào lịch sử, in hóa đơn A5 (giữ mẫu của bản app cũ); in hóa đơn trống để ghi tay.
- Lịch sử theo ngày: sửa, in lại, xóa.
- Tự lưu nháp đơn đang nhập dở.

## Cách hoạt động

- Các file chỉ cần đặt ở một địa chỉ HTTPS (GitHub Pages, Netlify, Cloudflare Pages…) để điện thoại tải về **lần đầu**. iPhone không chạy được file HTML mở từ app Tệp, nên phải mở qua đường link.
- `sw.js` (service worker) lưu toàn bộ app vào máy ở lần mở đầu; các lần sau mở không cần mạng.
- Lịch sử hóa đơn lưu trong IndexedDB, nháp lưu trong localStorage của trình duyệt trên chính điện thoại; không gửi đi đâu.

## Đưa lên mạng (miễn phí)

**GitHub Pages:** repo phải public (gói GitHub miễn phí) hoặc tài khoản GitHub Pro. Vào Settings → Pages → Build and deployment → *Deploy from a branch* → `main` / `(root)` → Save. Link có dạng `https://<tài-khoản>.github.io/<tên-repo>/`.

**Netlify (repo private vẫn dùng được):** vào <https://app.netlify.com/drop>, kéo thả cả thư mục dự án, nhận link HTTPS.

## Cài lên điện thoại

**iPhone/iPad (Safari):**

1. Mở link bằng Safari khi có mạng.
2. Bấm nút Chia sẻ → *Thêm vào MH chính* (Add to Home Screen) → để bật *Mở dưới dạng ứng dụng web* → *Thêm*.
3. Mở app bằng biểu tượng vừa thêm một lần khi có mạng. Từ đó chạy offline.

Dữ liệu của app trên màn hình chính tách riêng với Safari: hãy luôn mở bằng biểu tượng. Xóa biểu tượng app là xóa luôn lịch sử hóa đơn.

**Android (Chrome):** mở link → menu ⋮ → *Thêm vào màn hình chính* / *Cài đặt ứng dụng*.

## In hóa đơn

Điện thoại và máy in phải cùng mạng Wi-Fi. Hóa đơn khổ **A5**, 20 dòng mỗi trang; đơn hơn 20 món in thành nhiều trang, tổng tiền ở trang cuối.

- **iPhone/iPad:** bấm *In Hóa Đơn* → bảng chia sẻ hiện file PDF → chọn *In* → chọn máy in (AirPrint) → *In*. Máy in không hỗ trợ AirPrint: trong bảng chia sẻ chọn app của hãng máy in (Canon PRINT, HP Smart, Epson Smart Panel, Brother Mobile Connect…). Lý do đi qua PDF: từ iOS 27, lệnh in của trình duyệt không chạy khi mở web app từ màn hình chính.
- **Android / máy tính:** bấm *In Hóa Đơn* → hộp thoại in của máy → chọn máy in, khổ giấy A5. Không thấy máy in thì cài *Mopria Print Service* hoặc plugin in của hãng máy in từ CH Play. *Chia sẻ PDF* để gửi hóa đơn qua Zalo hoặc mở bằng app của hãng máy in.

## Định dạng đơn hàng

```
20 leo x 1.2
30 bap x 2
15 me x0.8
```

- Đơn giá nhập theo **nghìn đồng**, dùng dấu chấm cho phần lẻ: `1.2` = 1.200đ.
- Chữ `x` viết thường; dòng sai định dạng bị bỏ qua.

## Phát triển

- Chạy thử trên máy tính: `python3 -m http.server 8000` rồi mở <http://localhost:8000>. Mở thẳng file `index.html` sẽ không tạo được PDF và không có chế độ offline.
- **Sửa bất kỳ file nào của app thì tăng `VERSION` trong `sw.js`**, nếu không điện thoại vẫn dùng bản đã lưu. Điện thoại tải bản mới ở lần mở app có mạng và dùng nó từ lần mở kế tiếp (iPhone: vuốt tắt hẳn app rồi mở lại).
- Thêm file mới cho app thì thêm vào danh sách `ASSETS` trong `sw.js`.

```
index.html             Giao diện các màn hình
css/app.css            Giao diện + quy tắc in khổ A5
js/core.js             Đọc đơn hàng, định dạng tiền/ngày
js/store.js            Lưu lịch sử (IndexedDB) và nháp (localStorage)
js/invoice.js          Mẫu hóa đơn A5: dựng trang để xem/in và file PDF
js/app.js              Điều khiển màn hình, in, chia sẻ, lịch sử
sw.js                  Lưu app vào máy để chạy offline
manifest.webmanifest   Tên, biểu tượng khi thêm vào màn hình chính
vendor/jspdf.umd.min.js  Thư viện tạo PDF (jsPDF 4.2.1, MIT)
fonts/                 Noto Sans, Carlito Bold (font in trên hóa đơn)
icons/                 Biểu tượng app
```

Bản app Flutter cũ vẫn nằm trong lịch sử git (commit `ba40a9e`).
