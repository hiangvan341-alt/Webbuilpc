# Nâng cấp v2.0.5

Database đang dùng: chỉ chạy theo thứ tự:

1. `01_UPGRADE_EXISTING_TO_v2.0.5.sql`
2. `02_VERIFY_v2.0.5.sql`

Không chạy lại `schema.sql` và không chạy các migration phiên bản cũ.

Bản nâng cấp này tạo lại đúng chữ ký RPC `employee_delete_quote(p_token uuid, p_quote_id uuid)` và các RPC lịch sử báo giá liên quan, sau đó yêu cầu PostgREST tải lại schema cache.
