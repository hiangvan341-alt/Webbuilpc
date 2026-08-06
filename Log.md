# Log.md

## v1.7.0 — 06/08/2026 08:33 (Asia/Bangkok)

### Nội dung
- Chuyển ý nghĩa tài khoản user thành tài khoản nhân viên NOVA TECH PC.
- Sau đăng nhập, thanh menu hiển thị tên nhân viên và nút Lịch sử báo giá.
- Thêm thông tin khách hàng: tên, điện thoại, địa chỉ, ghi chú.
- Thêm nút Lưu báo giá và Lưu & In.
- Mỗi báo giá được lưu theo nhân viên, khách hàng, mã báo giá, thời gian và snapshot linh kiện/giá.
- Nhân viên chỉ xem lịch sử do chính mình tạo.
- Tìm báo giá theo mã, tên khách hoặc số điện thoại.

### SQL
- Thêm module `supabase/modules/30_quote_history.sql`.
- Thêm bảng `quote_history`.
- Thêm RPC `employee_save_quote`, `employee_list_quotes`, `admin_list_quote_history`.
- Sửa `user_login` trả về cả token và username.
- Cung cấp file nâng cấp đầy đủ `01_UPGRADE_EXISTING_TO_v1.7.0.sql` và file kiểm tra `02_VERIFY_v1.7.0.sql`.
