# Web Build PC NOVA TECH PC v1.9.0

React + Vite + Supabase, triển khai trên Vercel hoặc Render.

## Tính năng
- Chọn linh kiện lẻ hoặc cấu hình PC, không bắt buộc chọn đủ danh mục.
- Gửi yêu cầu đặt hàng về khu vực Admin.
- Cấu hình mẫu hiển thị trên tab Build PC.
- Admin có các tab riêng: Sản phẩm, Tài khoản, Báo giá, Yêu cầu đặt hàng, Cấu hình mẫu, Mẫu báo giá, Admin.
- Lịch sử báo giá toàn hệ thống có thể tìm theo tài khoản/user, khách hàng, số điện thoại và mã báo giá.

## Nâng cấp database đang dùng
Chạy:
1. `supabase/01_UPGRADE_EXISTING_TO_v1.9.0.sql`
2. `supabase/02_VERIFY_v1.9.0.sql`

Không chạy lại `schema.sql` trên database đang có dữ liệu.
