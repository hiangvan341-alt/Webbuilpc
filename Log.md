# Log.md

## v1.3.0 — 2026-08-06 07:52 (Asia/Bangkok)
- Thêm 3 chế độ hiển thị danh mục: lưới, cột gọn và hàng ngang.
- Thêm đăng nhập người dùng; tài khoản do admin tạo.
- Mật khẩu admin/người dùng chỉ lưu bcrypt, không có màn hình đọc lại mật khẩu.
- Cho phép trình duyệt đề nghị lưu mật khẩu bằng autocomplete chuẩn; web chỉ tự nhớ tên đăng nhập khi chọn.
- Admin chỉnh sửa tên công ty, hotline, email, địa chỉ, website, lưu ý và lời cảm ơn trên mẫu báo giá.
- Sửa toàn bộ hàm crypt dùng schema extensions để tránh lỗi 42883 trên Supabase.
