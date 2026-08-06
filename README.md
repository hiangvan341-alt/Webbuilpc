# Web Build PC v2.0.8

Website Build PC của NOVA TECH PC dùng React + Vite + Supabase.

## Nâng cấp database hiện tại

1. Chạy `supabase/01_UPGRADE_EXISTING_TO_v2.0.8.sql`.
2. Chạy `supabase/02_VERIFY_v2.0.8.sql`.
3. Không chạy lại `schema.sql` trên database đang có dữ liệu.

## Điểm mới

- Nút Lưu cấu hình nằm nổi bật tại Tóm tắt cấu hình.
- Lưu cấu hình theo tên trong tài khoản, không còn luồng bản nháp cục bộ.
- Tên khách hàng trong báo giá không bắt buộc.
- Tên báo giá: `Tên khách hàng - Tổng tiền`, hoặc `Khách lẻ - Tổng tiền`.
