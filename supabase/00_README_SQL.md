# SQL v1.7.0

## Database đang sử dụng
Chỉ chạy theo thứ tự:
1. `01_UPGRADE_EXISTING_TO_v1.7.0.sql`
2. `02_VERIFY_v1.7.0.sql`

Không chạy lại `schema.sql` trên database đang có dữ liệu.

## Database Supabase mới hoàn toàn
Chạy duy nhất `schema.sql`.

## Module
- `modules/20_user_accounts.sql`: tài khoản nhân viên.
- `modules/30_quote_history.sql`: lịch sử báo giá theo nhân viên và khách hàng.

Các file module dùng để sửa riêng từng phần. File nâng cấp đầy đủ đã bao gồm các module cần thiết.
