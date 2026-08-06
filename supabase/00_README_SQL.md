# SQL Web Build PC v2.0.8

## Supabase đang có dữ liệu
Chạy đúng thứ tự:

1. `01_UPGRADE_EXISTING_TO_v2.0.8.sql`
2. `02_VERIFY_v2.0.8.sql`

Không chạy lại `schema.sql`.

## Supabase mới hoàn toàn
Chạy:

1. `schema.sql`
2. `02_VERIFY_v2.0.8.sql`

SQL phiên bản cũ nằm trong `legacy/old_versions/` và đã đổi đuôi `.disabled` để tránh chạy nhầm.
