-- =========================================================
-- Web Build PC v1.4.0: quản lý toàn bộ tài khoản người dùng
-- =========================================================
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.user_accounts
  add column if not exists last_login_at timestamptz;

-- Tạo hoặc đặt lại mật khẩu nếu username đã tồn tại.
create or replace function public.admin_create_user_account(p_token uuid,p_username text,p_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$
declare v_admin uuid; v_username text:=lower(trim(p_username));
begin
  select s.admin_id into v_admin from public.admin_sessions s where s.token=p_token and s.expires_at>now() limit 1;
  if v_admin is null then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if length(v_username)<3 then raise exception 'Tên tài khoản phải có ít nhất 3 ký tự'; end if;
  if length(p_password)<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;
  insert into public.user_accounts(username,password_hash,created_by,is_active)
  values(v_username,extensions.crypt(p_password,extensions.gen_salt('bf',12)),v_admin,true)
  on conflict(username) do update set
    password_hash=extensions.crypt(p_password,extensions.gen_salt('bf',12)),
    is_active=true;
end $$;

create or replace function public.admin_list_user_accounts(p_token uuid)
returns table(id uuid,username text,is_active boolean,created_at timestamptz,last_login_at timestamptz)
language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  return query select u.id,u.username,u.is_active,u.created_at,u.last_login_at
  from public.user_accounts u order by u.created_at desc;
end $$;

create or replace function public.admin_update_user_account(p_token uuid,p_user_id uuid,p_username text default null,p_is_active boolean default null)
returns void language plpgsql security definer set search_path=public
as $$
declare v_username text;
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if not exists(select 1 from public.user_accounts where id=p_user_id) then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
  v_username:=case when p_username is null then null else lower(trim(p_username)) end;
  if v_username is not null and length(v_username)<3 then raise exception 'Tên tài khoản phải có ít nhất 3 ký tự'; end if;
  update public.user_accounts set
    username=coalesce(v_username,username),
    is_active=coalesce(p_is_active,is_active)
  where id=p_user_id;
  if p_is_active=false then delete from public.user_sessions where user_id=p_user_id; end if;
end $$;

create or replace function public.admin_reset_user_password(p_token uuid,p_user_id uuid,p_new_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if length(p_new_password)<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;
  update public.user_accounts set password_hash=extensions.crypt(p_new_password,extensions.gen_salt('bf',12)),is_active=true where id=p_user_id;
  if not found then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
  delete from public.user_sessions where user_id=p_user_id;
end $$;

create or replace function public.admin_delete_user_account(p_token uuid,p_user_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  delete from public.user_accounts where id=p_user_id;
  if not found then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
end $$;

create or replace function public.user_login(p_username text,p_password text)
returns table(token uuid)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_user uuid; v_token uuid;
begin
  select u.id into v_user from public.user_accounts u
  where lower(trim(u.username))=lower(trim(p_username)) and u.is_active
    and u.password_hash=extensions.crypt(p_password,u.password_hash) limit 1;
  if v_user is null then raise exception 'Sai tài khoản hoặc mật khẩu'; end if;
  delete from public.user_sessions where expires_at<now();
  insert into public.user_sessions(user_id) values(v_user) returning user_sessions.token into v_token;
  update public.user_accounts set last_login_at=now() where id=v_user;
  return query select v_token;
end $$;

grant execute on function public.admin_list_user_accounts(uuid) to anon,authenticated;
grant execute on function public.admin_update_user_account(uuid,uuid,text,boolean) to anon,authenticated;
grant execute on function public.admin_reset_user_password(uuid,uuid,text) to anon,authenticated;
grant execute on function public.admin_delete_user_account(uuid,uuid) to anon,authenticated;
grant execute on function public.admin_create_user_account(uuid,text,text) to anon,authenticated;
grant execute on function public.user_login(text,text) to anon,authenticated;
notify pgrst, 'reload schema';
