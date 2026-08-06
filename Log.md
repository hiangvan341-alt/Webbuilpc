# Web Build PC v2.0.0

- Gộp đăng nhập Admin và tài khoản người dùng vào một nút Đăng nhập.
- Chỉ hiển thị tab Admin sau khi đăng nhập bằng tài khoản Admin.
- Sắp xếp tab: Admin → Build PC → Hướng dẫn.
- Tài khoản người dùng đăng nhập và sử dụng web bình thường.
- Bỏ nút Đăng nhập Admin riêng.
- Không thay đổi cấu trúc SQL.

# Log.md

## v2.0.0 — 2026-08-06 08:55 (Asia/Bangkok)

- Bỏ điều kiện bắt buộc phải chọn đủ CPU/Mainboard/RAM/SSD/PSU/Case; hỗ trợ bán linh kiện lẻ.
- Nút Gửi yêu cầu đặt hàng tạo yêu cầu thật và chuyển vào tab Admin.
- Thêm trạng thái yêu cầu: Mới, Đã liên hệ, Hoàn tất, Đã hủy.
- Thêm cấu hình mẫu; Admin lưu cấu hình đang chọn và hiển thị cho người dùng chọn nhanh.
- Tách giao diện Admin thành các tab quản trị riêng.
- Admin xem lịch sử báo giá theo user hoặc toàn hệ thống qua tìm kiếm.
- Thêm SQL đầy đủ v2.0.0, file VERIFY và module 40 riêng.
- Chuyển migration v1.8.0 vào legacy với đuôi `.disabled`.
