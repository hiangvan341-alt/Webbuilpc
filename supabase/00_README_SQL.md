# SQL Web Build PC v1.8.0

## Database đang sử dụng từ phiên bản cũ

Chạy đúng thứ tự:

1. `01_UPGRADE_EXISTING_TO_v1.8.0.sql`
2. `02_VERIFY_v1.8.0.sql`

Không chạy lại `schema.sql` trên database đang có dữ liệu.

## Tạo Supabase mới hoàn toàn

Chỉ chạy:

- `schema.sql`

## Module riêng

- `modules/20_user_accounts.sql`: tài khoản đăng nhập và quản lý tài khoản.
- `modules/30_quote_history.sql`: lưu, xem, sửa, xóa lịch sử báo giá và quyền Admin xem toàn bộ.

## File cũ

Các migration cũ được chuyển vào `legacy/` và đổi đuôi `.disabled` để tránh chạy nhầm.
