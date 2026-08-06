# Log.md

## v1.6.0 — 06/08/2026 08:22 (Asia/Bangkok)

### Kiểm tra lỗi
- `schema.sql` v1.5.1 chứa nhiều phiên bản SQL nối tiếp nhau, cùng một RPC bị tạo lại nhiều lần.
- Migration v1.3.0 giả định `created_by` đã có; database được tạo từ một luồng khác nên phát sinh lỗi 42703.
- Migration v1.5.1 chuẩn hóa username trước khi xử lý trường hợp trùng hoa/thường, có nguy cơ lỗi unique.
- Frontend chỉ báo chung “Sai tài khoản hoặc mật khẩu”, không phân biệt password hash cũ không hợp lệ.
- Các migration cũ vẫn nằm cạnh file mới nên dễ bị chạy nhầm hoặc chạy sai thứ tự.

### Đã sửa
- Viết lại `schema.sql` thành nguồn cài mới duy nhất, không chồng lịch sử.
- Tạo file nâng cấp tổng hợp `01_UPGRADE_EXISTING_TO_v1.6.0.sql` có transaction, kiểm tra prerequisite và có thể chạy lặp lại.
- Tách module tài khoản user tại `modules/20_user_accounts.sql`.
- Drop RPC theo đúng chữ ký trước khi tạo lại.
- Bổ sung đầy đủ cột `created_by`, `updated_at`, `last_login_at`, `password_changed_at`.
- Xử lý username trùng sau chuẩn hóa bằng hậu tố an toàn, không xóa tài khoản.
- Thêm kiểm tra bcrypt hash và trạng thái “Cần cấp lại” trong Admin.
- Thêm `02_VERIFY_v1.6.0.sql` để kiểm tra extension, RPC và mật khẩu user.
- Chuyển SQL cũ sang `legacy/*.disabled` để không chạy nhầm.
