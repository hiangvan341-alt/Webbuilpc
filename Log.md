## v2.0.3 — 06/08/2026 09:41 (Asia/Bangkok)

- Sửa lỗi TypeScript `Cannot find name adminOpen` và `setAdminOpen`.
- Xóa đoạn render `AdminPanel` dạng modal còn sót từ phiên bản cũ.
- Khu vực Admin tiếp tục hiển thị trực tiếp trong tab Admin và các tab con.
- Không thay đổi cơ sở dữ liệu; không cần chạy SQL mới.
- So sánh với v2.0.2: chỉ sửa lỗi build, không thay đổi dữ liệu hay luồng nghiệp vụ.

# Log.md

## v2.0.1 — 06/08/2026 09:33 (Asia/Bangkok)
- Chuyển khu vực Admin từ hộp nổi/modal thành trang chính tích hợp trong website.
- Tab Admin nằm cùng cấp với Build PC và Hướng dẫn.
- Bên trong trang Admin giữ các tab con: Sản phẩm, Tài khoản, Báo giá, Yêu cầu đặt hàng, Cấu hình mẫu, Mẫu báo giá, Admin.
- Thanh tab con Admin bám trên đầu trang khi cuộn.
- Không thay đổi Supabase/SQL.

## v2.0.2 — 06/08/2026
- Thêm ô sửa giá bán ngay trên từng linh kiện đã chọn.
- Thêm ô sửa thời hạn bảo hành ngay trên từng linh kiện đã chọn.
- Tổng cấu hình cập nhật tức thì theo giá đã sửa.
- Báo giá, yêu cầu đặt hàng và cấu hình mẫu sử dụng giá/bảo hành đã chỉnh.
- Không thay đổi database; không cần chạy SQL.

## v2.0.5 — 2026-08-06 09:50 (Asia/Bangkok)

- Giữ trạng thái đăng nhập Admin trong `localStorage`, không mất khi chuyển tab hoặc tải lại trang.
- Tách nút trạng thái tài khoản và nút Đăng xuất, tránh bấm nhầm tên tài khoản thành đăng xuất.
- Tài khoản người dùng tiếp tục giữ phiên trong `localStorage`.
- Nút Lưu cấu hình nay lưu bản nháp và tự khôi phục khi mở lại web.
- Bổ sung migration đầy đủ tạo lại RPC xem, sửa, xóa báo giá, đặc biệt `employee_delete_quote`.
- Bổ sung file kiểm tra RPC và bảng lịch sử báo giá.
