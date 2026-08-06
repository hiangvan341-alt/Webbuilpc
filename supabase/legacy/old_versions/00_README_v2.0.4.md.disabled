# Cập nhật Supabase v2.0.4

## Database đang sử dụng
1. Chạy `01_UPGRADE_EXISTING_TO_v2.0.4.sql`.
2. Chạy `02_VERIFY_v2.0.4.sql`.
3. Đăng xuất tài khoản Admin trên web và đăng nhập lại để nhận vai trò mới.

Không chạy lại `schema.sql` trên database đang có dữ liệu.

## Supabase mới hoàn toàn
Chỉ chạy `schema.sql`.

## Phân quyền
- `super_admin`: Admin chính; có toàn bộ quyền và được tạo Admin phụ.
- `sub_admin`: có toàn bộ chức năng quản trị hiện tại, nhưng không thấy tab `Admin phụ` và RPC cũng từ chối tạo Admin.
