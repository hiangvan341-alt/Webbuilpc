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

## Phân quyền Admin v2.0.4
- `super_admin`: Admin chính, có toàn bộ quyền và được tạo Admin phụ.
- `sub_admin`: Admin phụ, có các quyền quản trị sản phẩm, user, báo giá, đơn hàng, cấu hình mẫu và mẫu báo giá; không được tạo thêm Admin.
- Database đang dùng: chạy `supabase/01_UPGRADE_EXISTING_TO_v2.0.4.sql`, sau đó chạy `supabase/02_VERIFY_v2.0.4.sql`.
