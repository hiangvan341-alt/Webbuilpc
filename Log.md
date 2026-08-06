# Log.md

## v2.0.8 — 06/08/2026 10:31 (Asia/Bangkok)

- Đưa nút **Lưu** lên vị trí nổi bật trong khung Tóm tắt cấu hình.
- Nút **Lưu** không còn lưu bản nháp cục bộ; tài khoản user mở trực tiếp phần đặt tên và quản lý cấu hình đã lưu.
- Bỏ luồng `pc-builder-draft` không còn sử dụng.
- Bỏ dấu `*` và bỏ yêu cầu bắt buộc nhập tên khách hàng khi lưu báo giá.
- Thêm `quote_name`: tên báo giá được tạo theo `Tên khách hàng + tổng tiền`; nếu để trống dùng `Khách lẻ + tổng tiền`.
- Lịch sử user và Admin hiển thị/tìm kiếm theo tên báo giá.
- SQL mới tách riêng thành `01_UPGRADE_EXISTING_TO_v2.0.8.sql` và `02_VERIFY_v2.0.8.sql`.
- SQL v2.0.7 chuyển vào `supabase/legacy/old_versions/` với đuôi `.disabled`.
