# SQL Web Build PC v2.0.6

## Database đang sử dụng
Chạy đúng thứ tự:
1. `01_UPGRADE_EXISTING_TO_v2.0.6.sql`
2. `02_VERIFY_v2.0.6.sql`

File nâng cấp là bản đồng bộ đầy đủ, không yêu cầu chạy migration cũ trước đó và không xóa dữ liệu nghiệp vụ.

## Supabase mới hoàn toàn
Chạy `schema.sql`, sau đó chạy `02_VERIFY_v2.0.6.sql`.

## Quy tắc thư mục
- `modules/`: SQL nguồn theo từng tính năng.
- `diagnostics/`: công cụ kiểm tra/sửa một trường hợp cụ thể.
- `legacy/old_versions/`: SQL phiên bản cũ đã đổi đuôi `.disabled`, không chạy.
