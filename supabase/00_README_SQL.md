# SQL v1.9.0

## Database đang dùng
Chỉ chạy theo thứ tự:
1. `01_UPGRADE_EXISTING_TO_v1.9.0.sql`
2. `02_VERIFY_v1.9.0.sql`

Không chạy lại `schema.sql` và không chạy file trong `legacy/`.

## Database mới hoàn toàn
Chạy duy nhất `schema.sql`, sau đó có thể chạy `02_VERIFY_v1.9.0.sql`.

## Module mới
- `modules/40_sample_configs_and_orders.sql`: cấu hình mẫu và yêu cầu đặt hàng.

Migration v1.9.0 có thể chạy lại an toàn: bảng/cột dùng `if not exists`, RPC cũ đúng chữ ký được xóa rồi tạo lại, không xóa sản phẩm, tài khoản hoặc báo giá hiện có.
