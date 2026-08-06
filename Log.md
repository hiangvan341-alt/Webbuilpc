# Log.md

## v1.5.0 — 2026-08-06 07:52 (Asia/Bangkok)
- Thêm 3 chế độ hiển thị danh mục: lưới, cột gọn và hàng ngang.
- Thêm đăng nhập người dùng; tài khoản do admin tạo.
- Mật khẩu admin/người dùng chỉ lưu bcrypt, không có màn hình đọc lại mật khẩu.
- Cho phép trình duyệt đề nghị lưu mật khẩu bằng autocomplete chuẩn; web chỉ tự nhớ tên đăng nhập khi chọn.
- Admin chỉnh sửa tên công ty, hotline, email, địa chỉ, website, lưu ý và lời cảm ơn trên mẫu báo giá.
- Sửa toàn bộ hàm crypt dùng schema extensions để tránh lỗi 42883 trên Supabase.


## v1.5.0 - 06/08/2026
- Admin xem toàn bộ tài khoản người dùng.
- Sửa tên, khóa/mở khóa, cấp lại mật khẩu và xóa user.
- Không hiển thị mật khẩu hiện tại; cấp mật khẩu mới sẽ vô hiệu hóa phiên đăng nhập cũ.
- Ghi nhận lần đăng nhập gần nhất.


## v1.5.0 - 06/08/2026
- Bỏ hình ảnh sản phẩm khỏi danh mục và dòng linh kiện đã chọn.
- Mặc định hiển thị danh mục theo hàng ngang để quan sát nhiều sản phẩm.
- Giữ tùy chọn lưới, cột gọn và hàng ngang.
- Bổ sung sắp xếp tồn kho từ ít đến nhiều.
- Làm lại giao diện đăng nhập khách hàng theo nhận diện NOVA TECH PC.
