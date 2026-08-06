-- =========================================================
-- Web Build PC v1.5.1
-- Sửa dứt điểm tạo tài khoản và đăng nhập người dùng
-- =========================================================

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.user_accounts add column if not exists created_by uuid;
alter table public.user_accounts add column if not exists updated_at timestamptz not null default now();
alter table public.user_accounts add column if not exists last_login_at timestamptz;

-- Chuẩn hóa username cũ để tránh khoảng trắng gây đăng nhập sai.
update public.user_accounts
set username = lower(trim(username)), updated_at = now()
where username is distinct from lower(trim(username));

-- Mỗi username chỉ tồn tại một lần, không phân biệt hoa/thường và khoảng trắng.
create unique index if not exists user_accounts_username_normalized_uidx
on public.user_accounts ((lower(trim(username))));

-- Xóa chính xác các hàm cũ trước khi tạo lại.
drop function if exists public.admin_create_user_account(uuid,text,text);
drop function if exists public.user_login(text,text);
drop function if exists public.admin_reset_user_password(uuid,uuid,text);

create function public.admin_create_user_account(
  p_token uuid,
  p_username text,
  p_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_admin_id uuid;
  v_username text := lower(trim(coalesce(p_username,'')));
  v_existing_id uuid;
begin
  select s.admin_id into v_admin_id
  from public.admin_sessions s
  where s.token = p_token and s.expires_at > now()
  limit 1;

  if v_admin_id is null then
    raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn';
  end if;
  if length(v_username) < 3 then
    raise exception 'Tên tài khoản phải có ít nhất 3 ký tự';
  end if;
  if length(coalesce(p_password,'')) < 6 then
    raise exception 'Mật khẩu phải có ít nhất 6 ký tự';
  end if;

  select u.id into v_existing_id
  from public.user_accounts u
  where lower(trim(u.username)) = v_username
  limit 1;

  if v_existing_id is null then
    insert into public.user_accounts(username,password_hash,created_by,is_active,updated_at)
    values(
      v_username,
      extensions.crypt(p_password, extensions.gen_salt('bf',12)),
      v_admin_id,
      true,
      now()
    );
  else
    update public.user_accounts
    set username = v_username,
        password_hash = extensions.crypt(p_password, extensions.gen_salt('bf',12)),
        created_by = v_admin_id,
        is_active = true,
        updated_at = now()
    where id = v_existing_id;

    delete from public.user_sessions where user_id = v_existing_id;
  end if;
end;
$$;

create function public.admin_reset_user_password(
  p_token uuid,
  p_user_id uuid,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if not public.is_valid_admin(p_token) then
    raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn';
  end if;
  if length(coalesce(p_new_password,'')) < 6 then
    raise exception 'Mật khẩu phải có ít nhất 6 ký tự';
  end if;

  update public.user_accounts
  set password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf',12)),
      is_active = true,
      updated_at = now()
  where id = p_user_id;

  if not found then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
  delete from public.user_sessions where user_id = p_user_id;
end;
$$;

create function public.user_login(
  p_username text,
  p_password text
)
returns table(token uuid)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_user public.user_accounts%rowtype;
  v_token uuid;
begin
  select u.* into v_user
  from public.user_accounts u
  where lower(trim(u.username)) = lower(trim(coalesce(p_username,'')))
    and u.is_active = true
  limit 1;

  if v_user.id is null
     or v_user.password_hash is null
     or v_user.password_hash <> extensions.crypt(coalesce(p_password,''), v_user.password_hash) then
    raise exception 'Sai tài khoản hoặc mật khẩu';
  end if;

  delete from public.user_sessions where expires_at < now();
  insert into public.user_sessions(user_id,expires_at)
  values(v_user.id, now() + interval '30 days')
  returning user_sessions.token into v_token;

  update public.user_accounts
  set last_login_at = now(), updated_at = now()
  where id = v_user.id;

  return query select v_token;
end;
$$;

grant execute on function public.admin_create_user_account(uuid,text,text) to anon,authenticated;
grant execute on function public.admin_reset_user_password(uuid,uuid,text) to anon,authenticated;
grant execute on function public.user_login(text,text) to anon,authenticated;

notify pgrst, 'reload schema';
