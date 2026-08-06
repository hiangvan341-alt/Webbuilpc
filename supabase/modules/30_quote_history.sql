-- MODULE 30: LỊCH SỬ BÁO GIÁ THEO NHÂN VIÊN / KHÁCH HÀNG
-- Có thể chạy lại an toàn. Không xóa lịch sử hiện có.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.quote_history (
  id uuid primary key default extensions.gen_random_uuid(),
  quote_code text not null unique,
  employee_id uuid references public.user_accounts(id) on delete set null,
  employee_username text not null,
  customer_name text not null,
  customer_phone text not null default '',
  customer_address text not null default '',
  customer_note text not null default '',
  items jsonb not null default '[]'::jsonb,
  total numeric(16,2) not null default 0,
  quote_settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.quote_history add column if not exists employee_id uuid;
alter table public.quote_history add column if not exists employee_username text not null default '';
alter table public.quote_history add column if not exists customer_name text not null default '';
alter table public.quote_history add column if not exists customer_phone text not null default '';
alter table public.quote_history add column if not exists customer_address text not null default '';
alter table public.quote_history add column if not exists customer_note text not null default '';
alter table public.quote_history add column if not exists items jsonb not null default '[]'::jsonb;
alter table public.quote_history add column if not exists total numeric(16,2) not null default 0;
alter table public.quote_history add column if not exists quote_settings jsonb not null default '{}'::jsonb;
alter table public.quote_history add column if not exists created_at timestamptz not null default now();
alter table public.quote_history add column if not exists updated_at timestamptz not null default now();

create index if not exists quote_history_employee_created_idx on public.quote_history(employee_id,created_at desc);
create index if not exists quote_history_customer_name_idx on public.quote_history(lower(customer_name));
create index if not exists quote_history_customer_phone_idx on public.quote_history(customer_phone);

alter table public.quote_history enable row level security;

-- user_login v1.7 trả thêm username để frontend hiển thị đúng tài khoản nhân viên.
drop function if exists public.user_login(text,text);
create function public.user_login(p_username text,p_password text)
returns table(token uuid,username text)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_user public.user_accounts%rowtype; v_token uuid;
begin
  select u.* into v_user from public.user_accounts u
  where lower(trim(u.username))=lower(trim(coalesce(p_username,''))) and u.is_active limit 1;
  if v_user.id is null then raise exception 'Sai tài khoản hoặc mật khẩu'; end if;
  if v_user.password_hash is null or v_user.password_hash !~ '^[$]2[aby][$][0-9]{2}[$]' then
    raise exception 'Tài khoản chưa có mật khẩu hợp lệ. Vui lòng liên hệ Admin để cấp lại mật khẩu';
  end if;
  if v_user.password_hash <> extensions.crypt(coalesce(p_password,''),v_user.password_hash) then
    raise exception 'Sai tài khoản hoặc mật khẩu';
  end if;
  delete from public.user_sessions where expires_at<now();
  insert into public.user_sessions(user_id,expires_at) values(v_user.id,now()+interval '30 days') returning user_sessions.token into v_token;
  update public.user_accounts set last_login_at=now(),updated_at=now() where id=v_user.id;
  return query select v_token,v_user.username;
end $$;

-- Nhân viên lưu báo giá. Giá/tên sản phẩm được chụp snapshot trong JSONB.
drop function if exists public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb);
create function public.employee_save_quote(
  p_token uuid,
  p_customer_name text,
  p_customer_phone text,
  p_customer_address text,
  p_customer_note text,
  p_items jsonb,
  p_total numeric,
  p_quote_settings jsonb
)
returns table(quote_code text)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_user_id uuid; v_username text; v_code text;
begin
  select u.id,u.username into v_user_id,v_username
  from public.user_sessions s join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
  if v_user_id is null then raise exception 'Phiên nhân viên không hợp lệ hoặc đã hết hạn'; end if;
  if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'Vui lòng nhập tên khách hàng'; end if;
  if jsonb_typeof(coalesce(p_items,'[]'::jsonb))<>'array' or jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'Báo giá chưa có sản phẩm'; end if;
  v_code := 'BG-'||to_char(clock_timestamp(),'YYYYMMDD-HH24MISS')||'-'||upper(substr(replace(extensions.gen_random_uuid()::text,'-',''),1,4));
  insert into public.quote_history(quote_code,employee_id,employee_username,customer_name,customer_phone,customer_address,customer_note,items,total,quote_settings)
  values(v_code,v_user_id,v_username,trim(p_customer_name),trim(coalesce(p_customer_phone,'')),trim(coalesce(p_customer_address,'')),trim(coalesce(p_customer_note,'')),p_items,greatest(coalesce(p_total,0),0),coalesce(p_quote_settings,'{}'::jsonb));
  return query select v_code;
end $$;

-- Nhân viên chỉ xem lịch sử do chính mình tạo.
drop function if exists public.employee_list_quotes(uuid,text);
create function public.employee_list_quotes(p_token uuid,p_search text default null)
returns table(id uuid,quote_code text,customer_name text,customer_phone text,customer_address text,customer_note text,total numeric,created_at timestamptz,items jsonb)
language plpgsql security definer set search_path=public
as $$
declare v_user_id uuid; v_search text:=lower(trim(coalesce(p_search,'')));
begin
  select s.user_id into v_user_id from public.user_sessions s join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
  if v_user_id is null then raise exception 'Phiên nhân viên không hợp lệ hoặc đã hết hạn'; end if;
  return query select q.id,q.quote_code,q.customer_name,q.customer_phone,q.customer_address,q.customer_note,q.total,q.created_at,q.items
  from public.quote_history q
  where q.employee_id=v_user_id and (v_search='' or lower(q.customer_name) like '%'||v_search||'%' or lower(q.customer_phone) like '%'||v_search||'%' or lower(q.quote_code) like '%'||v_search||'%')
  order by q.created_at desc;
end $$;

-- Admin xem toàn bộ lịch sử của tất cả nhân viên.
drop function if exists public.admin_list_quote_history(uuid,text);
create function public.admin_list_quote_history(p_token uuid,p_search text default null)
returns table(id uuid,quote_code text,employee_username text,customer_name text,customer_phone text,total numeric,created_at timestamptz,items jsonb)
language plpgsql security definer set search_path=public
as $$
declare v_search text:=lower(trim(coalesce(p_search,'')));
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  return query select q.id,q.quote_code,q.employee_username,q.customer_name,q.customer_phone,q.total,q.created_at,q.items
  from public.quote_history q
  where v_search='' or lower(q.customer_name) like '%'||v_search||'%' or lower(q.customer_phone) like '%'||v_search||'%' or lower(q.quote_code) like '%'||v_search||'%' or lower(q.employee_username) like '%'||v_search||'%'
  order by q.created_at desc;
end $$;

revoke all on function public.user_login(text,text) from public;
revoke all on function public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb) from public;
revoke all on function public.employee_list_quotes(uuid,text) from public;
revoke all on function public.admin_list_quote_history(uuid,text) from public;
grant execute on function public.user_login(text,text) to anon,authenticated;
grant execute on function public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb) to anon,authenticated;
grant execute on function public.employee_list_quotes(uuid,text) to anon,authenticated;
grant execute on function public.admin_list_quote_history(uuid,text) to anon,authenticated;

notify pgrst,'reload schema';
