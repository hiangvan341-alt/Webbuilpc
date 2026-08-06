# Web Build PC NOVA TECH PC v1.6.0

## Nâng cấp website
1. Đưa toàn bộ source lên GitHub.
2. Chờ Vercel/Render build lại.
3. Với Supabase đang dùng: chạy `supabase/01_UPGRADE_EXISTING_TO_v1.6.0.sql`.
4. Chạy `supabase/02_VERIFY_v1.6.0.sql` và kiểm tra mọi dòng chức năng đều là `OK`.
5. Trong Admin, tài khoản nào hiện **Cần cấp lại** thì bấm chìa khóa và cấp mật khẩu mới một lần.

## Cài Supabase mới
Chỉ chạy `supabase/schema.sql`, không chạy các migration cũ.

## Cấu trúc SQL
- `schema.sql`: cài mới hoàn chỉnh, không nối lịch sử phiên bản.
- `01_UPGRADE_EXISTING_TO_v1.6.0.sql`: nâng cấp database hiện có, có thể chạy lại.
- `02_VERIFY_v1.6.0.sql`: kiểm tra sau nâng cấp.
- `modules/`: SQL tách theo chức năng.
- `diagnostics/`: câu lệnh xử lý thủ công.
- `legacy/*.disabled`: bản cũ chỉ để đối chiếu, không được chạy.

## Tài khoản mặc định khi cài mới
- Tên đăng nhập: `admin`
- Mật khẩu: `Do12345`

Hãy tạo admin mới và đổi cách quản trị trước khi công bố hệ thống.
