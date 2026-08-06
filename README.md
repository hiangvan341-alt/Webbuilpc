# Web Build PC v2.0.7

## Nâng cấp Supabase đang dùng

Chạy đúng thứ tự:

1. `supabase/01_UPGRADE_EXISTING_TO_v2.0.7.sql`
2. `supabase/02_VERIFY_v2.0.7.sql`

Không chạy `schema.sql` trên database đang có dữ liệu. Các SQL phiên bản cũ nằm trong `supabase/legacy/old_versions`.

## Tính năng mới

- Thông báo giao diện web thay cho alert/confirm/prompt của trình duyệt.
- User quản lý cấu hình đã lưu: thêm, sửa, xóa, sử dụng lại.
- Admin xem cấu hình của từng user và chuyển thành cấu hình mẫu.
- Admin bật/tắt cấu hình mẫu công khai.
- Hướng dẫn quản trị nằm ngay trong tab Admin.
