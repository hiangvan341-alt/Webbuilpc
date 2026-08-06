# Log.md

## v2.0.7 — 06/08/2026 (Asia/Bangkok)

- Thay toàn bộ `window.alert`, `window.confirm`, `window.prompt` bằng toast, hộp xác nhận và hộp nhập liệu đồng bộ giao diện NOVA TECH PC.
- Thêm tab con **Hướng dẫn Admin**.
- Tài khoản user có thể đặt tên, lưu, xem, sử dụng, sửa và xóa cấu hình riêng.
- Admin xem cấu hình đã lưu của toàn bộ user và đưa một cấu hình thành cấu hình mẫu công khai.
- Admin chọn công khai/ẩn khi tạo cấu hình mẫu; có thể sửa tên, mô tả, trạng thái hiển thị và xóa cấu hình mẫu.
- Giữ chức năng cấp lại mật khẩu user bằng hộp nhập mật khẩu riêng, không hiển thị mật khẩu cũ.
- Thêm bảng `user_saved_configs` và các RPC quản lý cấu hình.
- SQL hiện hành chỉ còn v2.0.7; SQL v2.0.6 đã chuyển vào `supabase/legacy/old_versions`.
- File kiểm tra v2.0.7 trả về một bảng tổng hợp OK/MISSING.
