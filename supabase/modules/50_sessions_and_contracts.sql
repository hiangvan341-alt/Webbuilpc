-- MODULE 50: Xác thực phiên, đăng xuất và đồng bộ hợp đồng RPC - v2.0.6
-- Có thể chạy lặp lại, không xóa tài khoản hoặc dữ liệu nghiệp vụ.

begin;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- Đảm bảo user_login luôn trả cả token và username đúng với frontend.
drop function if exists public.user_login(text,text);
create function public.user_login(p_username text,p_password text)
returns table(token uuid,username text)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_user public.user_accounts%rowtype; v_token uuid;
begin
  select u.* into v_user
  from public.user_accounts u
  where lower(trim(u.username))=lower(trim(coalesce(p_username,'')))
    and u.is_active
    and u.password_hash=extensions.crypt(coalesce(p_password,''),u.password_hash)
  limit 1;
  if v_user.id is null then raise exception 'Sai tài khoản hoặc mật khẩu'; end if;
  delete from public.user_sessions where expires_at<now();
  insert into public.user_sessions(user_id,expires_at)
  values(v_user.id,now()+interval '30 days') returning user_sessions.token into v_token;
  update public.user_accounts set last_login_at=now(),updated_at=now() where id=v_user.id;
  return query select v_token,v_user.username;
end $$;

-- Kiểm tra phiên khi tải lại trang hoặc chuyển tab.
drop function if exists public.validate_admin_session(uuid);
create function public.validate_admin_session(p_token uuid)
returns table(valid boolean,username text,role text)
language sql security definer set search_path=public
as $$
  select true,a.username,a.role
  from public.admin_sessions s
  join public.admin_accounts a on a.id=s.admin_id
  where s.token=p_token and s.expires_at>now() and a.is_active
  union all
  select false,''::text,'sub_admin'::text
  where not exists(
    select 1 from public.admin_sessions s
    join public.admin_accounts a on a.id=s.admin_id
    where s.token=p_token and s.expires_at>now() and a.is_active
  )
  limit 1
$$;

drop function if exists public.validate_user_session(uuid);
create function public.validate_user_session(p_token uuid)
returns table(valid boolean,username text)
language sql security definer set search_path=public
as $$
  select true,u.username
  from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active
  union all
  select false,''::text
  where not exists(
    select 1 from public.user_sessions s
    join public.user_accounts u on u.id=s.user_id
    where s.token=p_token and s.expires_at>now() and u.is_active
  )
  limit 1
$$;

-- Đăng xuất thật sự: xóa token ở database thay vì chỉ xóa trình duyệt.
drop function if exists public.admin_logout(uuid);
create function public.admin_logout(p_token uuid)
returns void language sql security definer set search_path=public
as $$ delete from public.admin_sessions where token=p_token $$;

drop function if exists public.user_logout(uuid);
create function public.user_logout(p_token uuid)
returns void language sql security definer set search_path=public
as $$ delete from public.user_sessions where token=p_token $$;

-- Token rỗng là khách vãng lai. Token được gửi nhưng hết hạn phải báo lỗi rõ ràng.
drop function if exists public.create_order_request(uuid,text,text,text,text,jsonb,numeric);
create function public.create_order_request(
  p_token uuid,p_customer_name text,p_customer_phone text,p_customer_address text,
  p_customer_note text,p_items jsonb,p_total numeric
)
returns table(request_code text)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_user uuid; v_username text:=''; v_code text;
begin
  if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'Vui lòng nhập tên khách hàng'; end if;
  if length(trim(coalesce(p_customer_phone,'')))<6 then raise exception 'Vui lòng nhập số điện thoại hợp lệ'; end if;
  if jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'Chưa chọn sản phẩm'; end if;
  if p_token is not null then
    select s.user_id,u.username into v_user,v_username
    from public.user_sessions s join public.user_accounts u on u.id=s.user_id
    where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
    if v_user is null then raise exception 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại'; end if;
  end if;
  v_code:='DH-'||to_char(now(),'YYYYMMDD-HH24MISS')||'-'||upper(substr(encode(extensions.gen_random_bytes(2),'hex'),1,4));
  insert into public.order_requests(request_code,employee_id,employee_username,customer_name,customer_phone,customer_address,customer_note,items,total)
  values(v_code,v_user,coalesce(v_username,''),trim(p_customer_name),trim(p_customer_phone),trim(coalesce(p_customer_address,'')),trim(coalesce(p_customer_note,'')),p_items,greatest(coalesce(p_total,0),0));
  return query select v_code;
end $$;

-- Chuẩn hóa slug theo schema extension của Supabase.
create or replace function public.slugify_product(p_name text)
returns text language sql immutable set search_path=public,extensions
as $$ select lower(regexp_replace(unaccent(trim(coalesce(p_name,''))),'[^a-zA-Z0-9]+','-','g')) $$;

revoke all on function public.user_login(text,text) from public;
revoke all on function public.validate_admin_session(uuid) from public;
revoke all on function public.validate_user_session(uuid) from public;
revoke all on function public.admin_logout(uuid) from public;
revoke all on function public.user_logout(uuid) from public;
revoke all on function public.create_order_request(uuid,text,text,text,text,jsonb,numeric) from public;
grant execute on function public.user_login(text,text) to anon,authenticated;
grant execute on function public.validate_admin_session(uuid) to anon,authenticated;
grant execute on function public.validate_user_session(uuid) to anon,authenticated;
grant execute on function public.admin_logout(uuid) to anon,authenticated;
grant execute on function public.user_logout(uuid) to anon,authenticated;
grant execute on function public.create_order_request(uuid,text,text,text,text,jsonb,numeric) to anon,authenticated;

create table if not exists public.app_schema_version(version text primary key,applied_at timestamptz not null default now(),note text not null default '');
insert into public.app_schema_version(version,note)
values('2.0.6','Full RPC synchronization, session validation/logout and frontend contract fixes')
on conflict(version) do update set applied_at=now(),note=excluded.note;

notify pgrst,'reload schema';
commit;
