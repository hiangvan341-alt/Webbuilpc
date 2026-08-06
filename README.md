# Web Build PC – NOVA TECH PC v1.2.0

## Chức năng
- Người dùng chọn linh kiện, tính tổng tiền, kiểm tra tương thích và in báo giá theo mẫu NOVA TECH PC.
- Admin đăng nhập bằng tài khoản ban đầu `admin` / `Do12345`.
- Admin tải Excel và hệ thống chỉ đọc 5 cột: `Nhóm hàng(3 Cấp)`, `Tên hàng`, `Giá bán`, `Tồn kho`, `Bảo hành`.
- Admin có thể tạo thêm tài khoản quản trị bằng tên đăng nhập và mật khẩu.
- Mật khẩu admin được băm bcrypt trong Supabase, không lưu văn bản thuần.

## Cài đặt
1. Tạo project Supabase.
2. Mở SQL Editor, chạy toàn bộ `supabase/schema.sql`.
3. Tạo file `.env` từ `.env.example` và điền URL + anon key.
4. Chạy `npm install`, sau đó `npm run dev`.
5. Đẩy lên GitHub và import repository vào Vercel.

## Excel
File có thể chứa nhiều cột. Web tự tìm đúng tên 5 cột cần dùng, không yêu cầu thứ tự cột cố định. Dữ liệu được cập nhật theo tên sản phẩm và nhóm hàng; tải lại file sẽ cập nhật giá, tồn kho và bảo hành thay vì tạo trùng.

## Bảo mật
Đổi hoặc tạo tài khoản admin mới ngay sau khi triển khai. Các thao tác nhập Excel và tạo tài khoản đều đi qua hàm `security definer` có kiểm tra session quản trị 12 giờ.


## Phân loại danh mục Excel

Web tự nhận diện `Nhóm hàng(3 Cấp)` và đưa sản phẩm vào đúng thứ tự: CPU → Mainboard → RAM → VGA → SSD/HDD → PSU → Case → Tản nhiệt → Màn hình → Phụ kiện. Các nhóm Phụ phí, Dịch vụ, COMBO và AIO nguyên bộ không được nhập vào công cụ build PC.

Trong cửa sổ chọn linh kiện có bộ lọc theo tên, thương hiệu, giá, tồn kho và sắp xếp sản phẩm.


## Cập nhật v1.3.0

Nếu hệ thống đã chạy schema của v1.2.0, chỉ cần chạy `supabase/migration_v1.3.0.sql` trong Supabase SQL Editor, sau đó đưa source mới lên GitHub và redeploy Vercel/Render.

- Danh mục có ba kiểu xem: lưới, cột gọn, hàng ngang.
- Admin tạo được tài khoản người dùng và tài khoản admin.
- Không có chức năng xem lại mật khẩu; database chỉ lưu bcrypt hash.
- Ô đăng nhập dùng `autocomplete` chuẩn để Chrome/Edge có thể đề nghị lưu mật khẩu. Web chỉ tự lưu tên đăng nhập khi người dùng đánh dấu ghi nhớ.
- Mẫu báo giá được chỉnh trong trang quản trị và lưu vào Supabase.
