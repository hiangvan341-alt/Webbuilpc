# SQL Web Build PC v1.6.0

## Hệ thống đang chạy bản cũ
Chỉ chạy theo thứ tự:
1. `01_UPGRADE_EXISTING_TO_v1.6.0.sql`
2. `02_VERIFY_v1.6.0.sql`

Không chạy lại migration v1.3.0, v1.4.0 hoặc v1.5.1. Chúng đã được chuyển vào `legacy/*.disabled` để tránh chạy nhầm.

## Cài Supabase mới hoàn toàn
Chạy duy nhất `schema.sql`, sau đó chạy `02_VERIFY_v1.6.0.sql`.

## Quy tắc từ v1.6.0
- `schema.sql`: nguồn chuẩn để cài mới, không chứa lịch sử chồng nối.
- `01_UPGRADE...`: một file nâng cấp đầy đủ từ database đang có.
- `modules/`: tách theo chức năng để bảo trì; người dùng thông thường không cần chạy riêng.
- `diagnostics/`: câu lệnh kiểm tra/sửa thủ công, không chạy đại trà.
- Mọi RPC cũ được `drop function ... (đúng chữ ký)` trước khi tạo lại.
- Mọi migration phải chạy lặp lại được và không xóa dữ liệu nghiệp vụ.
