-- Chỉ dùng khi cần cấp lại trực tiếp bằng SQL.
-- Thay user01 và MatKhauMoi123 trước khi chạy.
update public.user_accounts
set password_hash=extensions.crypt('MatKhauMoi123',extensions.gen_salt('bf',12)),
    password_changed_at=now(),is_active=true,updated_at=now()
where lower(trim(username))=lower(trim('user01'));
delete from public.user_sessions
where user_id in(select id from public.user_accounts where lower(trim(username))=lower(trim('user01')));
