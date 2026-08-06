# Web Build PC NOVA TECH PC v1.7.0

## Chức năng chính mới
- Tài khoản người dùng được xác định là **tài khoản nhân viên**.
- Nhân viên đăng nhập để tạo, lưu và in báo giá cho từng khách hàng.
- Mỗi báo giá lưu ảnh chụp tên sản phẩm, giá, bảo hành và tổng tiền tại thời điểm lập.
- Lịch sử tách riêng theo từng nhân viên.
- Tìm lịch sử theo tên khách hàng, số điện thoại hoặc mã báo giá.
- Admin có RPC xem lịch sử của toàn bộ nhân viên.

## Nâng cấp database hiện có
1. Chạy `supabase/01_UPGRADE_EXISTING_TO_v1.7.0.sql`.
2. Chạy `supabase/02_VERIFY_v1.7.0.sql`.
3. Không chạy lại migration cũ hoặc `schema.sql` trên database đang có dữ liệu.

## Cài Supabase mới
Chạy duy nhất `supabase/schema.sql`.

## Deploy
- Build command: `npm run build`
- Output: `dist`
- Environment: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
