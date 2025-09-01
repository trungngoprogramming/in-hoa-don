# Ứng Dụng In Hóa Đơn Bánh Kẹo Hùng Chính - Flutter

Ứng dụng Flutter để quản lý và in hóa đơn cho cửa hàng bánh kẹo với giao diện hiện đại và đầy đủ tính năng.

## Tính Năng Chính

- **Nhập đơn hàng**: Giao diện nhập thông tin khách hàng và đơn hàng
- **Xử lý thông minh**: Sử dụng regex để phân tích và xử lý thông tin đơn hàng
- **Chỉnh sửa đơn hàng**: Giao diện chỉnh sửa với tính toán tự động
- **In hóa đơn**: In hóa đơn với layout A5 chuyên nghiệp
- **Quản lý lịch sử**: Xem, tìm kiếm, xóa và in lại hóa đơn theo ngày
- **Giao diện hiện đại**: UI/UX thân thiện và responsive

## Cài Đặt

### Yêu Cầu Hệ Thống
- Flutter SDK (version 3.0.0 trở lên)
- Dart SDK
- Android Studio / VS Code

### Bước 1: Clone và Cài Đặt Dependencies

```bash
# Cài đặt dependencies
flutter pub get
```

### Bước 2: Chạy Ứng Dụng

```bash
# Chạy ứng dụng
flutter run
```

## Cách Sử Dụng

### 1. Tạo Đơn Hàng Mới
- Mở ứng dụng
- Nhấn "Tạo Đơn Hàng Mới"
- Nhập tên khách hàng
- Nhập thông tin đơn hàng theo format: `20 leo x 1.2`
- Nhấn "Tiếp Tục" để xử lý

### 2. Chỉnh Sửa Đơn Hàng
- Xem và chỉnh sửa thông tin đã được xử lý
- Thêm/xóa sản phẩm
- Tính toán tự động thành tiền
- Nhấn "In Hóa Đơn" để in

### 3. In Hóa Đơn
- Hóa đơn sẽ hiển thị dưới dạng PDF
- Có thể in trực tiếp hoặc chia sẻ
- Layout A5 chuyên nghiệp

### 4. Quản Lý Lịch Sử
- Chọn ngày để xem hóa đơn
- Xem danh sách hóa đơn
- In lại hoặc xóa hóa đơn

## Cấu Trúc Dự Án

```
lib/
├── main.dart              # Entry point
├── models/
│   ├── app_state.dart     # State management
│   └── invoice_model.dart # Data models
├── screens/
│   ├── home_screen.dart   # Màn hình chính
│   ├── order_form_screen.dart # Nhập đơn hàng
│   ├── edit_order_screen.dart # Chỉnh sửa đơn hàng
│   ├── invoice_screen.dart # In hóa đơn
│   └── history_screen.dart # Lịch sử
├── utils/
│   └── order_parser.dart  # Xử lý đơn hàng
└── widgets/               # Custom widgets
```

## Công Nghệ Sử Dụng

### Frontend
- Flutter 3.0+
- Riverpod (State Management)
- Material Design 3
- PDF Generation
- Shared Preferences (Local Storage)

### Dependencies
- `flutter_riverpod`: State management
- `shared_preferences`: Local storage
- `intl`: Internationalization
- `printing`: PDF printing
- `pdf`: PDF generation
- `http`: HTTP requests (nếu cần)

## Lưu Ý

- Dữ liệu được lưu locally trên thiết bị
- Hóa đơn được lưu theo ngày
- Định dạng đơn hàng: `số lượng tên_sản_phẩm x đơn_giá` (ví dụ: `20 leo x 1.2`)
- Đơn giá sẽ được nhân 1000 để chuyển sang VND

## Hỗ Trợ

Nếu có vấn đề hoặc câu hỏi, vui lòng liên hệ để được hỗ trợ.
