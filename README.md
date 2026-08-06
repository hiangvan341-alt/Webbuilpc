# Web Build PC v2.0.3

## Cập nhật v2.0.3

Sau khi chọn sản phẩm vào cấu hình, có thể sửa trực tiếp **Giá bán** và **Bảo hành**. Tổng tiền, báo giá, yêu cầu đặt hàng và cấu hình mẫu sẽ dùng thông tin đã chỉnh. Phiên bản này không cần chạy SQL mới.


Khu vực Admin được tích hợp trực tiếp thành một trang trong website, không còn mở bằng hộp nổi.

## Tab chính khi đăng nhập Admin
`Admin → Build PC → Hướng dẫn`

## Tab con trong Admin
- Sản phẩm
- Tài khoản
- Báo giá
- Yêu cầu đặt hàng
- Cấu hình mẫu
- Mẫu báo giá
- Admin

Không cần chạy SQL mới cho phiên bản này.

## v2.0.6

- Phiên Admin được giữ khi chuyển giữa Admin, Build PC và Hướng dẫn, đồng thời vẫn còn sau khi tải lại trang cho tới khi bấm Đăng xuất.
- Tên tài khoản không còn là nút đăng xuất; nút Đăng xuất được tách riêng.
- `Lưu` trong Build PC là lưu bản nháp cấu hình trên chính trình duyệt đang dùng. Web tự khôi phục bản nháp này khi mở lại. Đây không phải lịch sử báo giá và không đồng bộ sang máy khác.
- Database hiện có phải chạy `supabase/01_UPGRADE_EXISTING_TO_v2.0.6.sql`, sau đó chạy file kiểm tra.


## v2.0.6
- Đồng bộ đầy đủ toàn bộ RPC frontend với Supabase.
- Xác thực lại phiên khi tải trang và chuyển tab.
- Đăng xuất xóa session ở Supabase.
- Không che lỗi database bằng thông báo sai mật khẩu.
- SQL cũ chuyển vào `supabase/legacy/old_versions`.
