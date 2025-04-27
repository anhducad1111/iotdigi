# Yêu Cầu Chức Năng Ứng Dụng Giám Sát Đồng Hồ Nước

## A. Chức Năng Người Dùng

### 1. Quản Lý Tài Khoản
- Đăng ký/đăng nhập với email
- Xem và cập nhật thông tin cá nhân
- Quên mật khẩu qua OTP

### 2. Quản Lý Đồng Hồ
- Xem danh sách đồng hồ được gắn
- Thêm đồng hồ mới (nhập mã số)
- Xem thông tin chi tiết đồng hồ
- Điều chỉnh độ sáng LED của ESP32-CAM

### 3. Theo Dõi Chỉ Số
- Xem số đồng hồ hiện tại (OCR)
- Xem ảnh chụp thời gian thực
- Xem biểu đồ tiêu thụ theo thời gian
- Xuất báo cáo sử dụng

### 4. Giám Sát Môi Trường
- Theo dõi nhiệt độ (DHT22)
- Theo dõi độ ẩm (DHT22)
- Theo dõi chất lượng không khí (MQ2)
- Xem biểu đồ thống kê môi trường
- Cài đặt ngưỡng cảnh báo

### 5. Quản Lý Hóa Đơn
- Xem hóa đơn hàng tháng
- Thanh toán online (bank/ví điện tử)
- Xem lịch sử thanh toán
- Tải hóa đơn điện tử

### 6. Thông Báo & Cảnh Báo
- Cảnh báo tiêu thụ nước bất thường
- Thông báo hạn thanh toán
- Cảnh báo rò rỉ nước
- Cảnh báo cháy (từ cảm biến MQ2)
- Cảnh báo nhiệt độ/độ ẩm bất thường
- Thông báo bảo trì thiết bị

## B. Chức Năng Quản Trị Viên

### 1. Quản Lý Hệ Thống
- Theo dõi trạng thái toàn bộ thiết bị

### 2. Quản Lý Người Dùng
- Xem danh sách người dùng
- Phân quyền tài khoản

### 3. Quản Lý Thiết Bị
- Thêm/xóa đồng hồ vào hệ thống
- Gán đồng hồ cho người dùng
- Cấu hình thông số đồng hồ
- Điều chỉnh độ sáng LED từ xa
- Hiệu chỉnh cảm biến môi trường
- Lên lịch bảo trì

### 4. Quản Lý Hóa Đơn
- Cấu hình biểu giá nước
- Duyệt và phát hành hóa đơn
- Theo dõi thanh toán
- Xử lý khiếu nại

### 5. Phân Tích & Báo Cáo
- Thống kê tiêu thụ nước
- Báo cáo doanh thu
- Phân tích mẫu sử dụng
- Dự báo tiêu thụ

### 6. Cài Đặt Hệ Thống
- Cấu hình server
- Quản lý backup dữ liệu
- Thiết lập thông báo
- Cấu hình bảo mật
- Cài đặt ngưỡng cảnh báo mặc định