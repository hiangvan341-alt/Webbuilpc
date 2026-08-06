# Log.md

## Web Build PC v1.8.0 — 06/08/2026 (Asia/Bangkok)

### Giao diện
- Bỏ mã báo giá và tên tài khoản khỏi mẫu báo giá in.
- Nút chưa đăng nhập chỉ hiển thị “Đăng nhập”.
- Khi đã đăng nhập hiển thị tên tài khoản và “Đăng xuất tài khoản”.
- Bỏ toàn bộ chữ “nhân viên” trong cửa sổ đăng nhập.
- Hoàn thiện 2 tab Build PC và Hướng dẫn; tab Hướng dẫn có quy trình 6 bước.

### Lịch sử báo giá
- Tài khoản được xem chi tiết báo giá đã tạo.
- Cho phép sửa tên/SĐT/địa chỉ/ghi chú khách hàng.
- Cho phép sửa số lượng và đơn giá từng sản phẩm, tự tính lại tổng tiền.
- Cho phép xóa báo giá có xác nhận.
- Admin xem lịch sử báo giá của toàn bộ tài khoản và tìm kiếm theo tài khoản/khách/mã/SĐT.

### Supabase
- Thêm RPC `employee_update_quote`.
- Thêm RPC `employee_delete_quote`.
- Mở rộng dữ liệu trả về của `employee_list_quotes` và `admin_list_quote_history`.
- Tách module `modules/30_quote_history.sql`.
- Có migration đầy đủ `01_UPGRADE_EXISTING_TO_v1.8.0.sql` và kiểm tra `02_VERIFY_v1.8.0.sql`.
- Chuyển migration cũ vào `supabase/legacy/*.disabled`.
