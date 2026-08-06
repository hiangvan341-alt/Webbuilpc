-- Web Build PC v2.0.8
-- Chỉ chạy file này trên Supabase đang có dữ liệu.
-- Không xóa sản phẩm, tài khoản, báo giá hoặc cấu hình đã lưu.

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.quote_history
  add column if not exists quote_name text not null default '';

update public.quote_history
set quote_name = coalesce(nullif(trim(customer_name), ''), 'Khách lẻ')
  || ' - '
  || replace(to_char(round(greatest(coalesce(total,0),0)), 'FM999,999,999,999,990'), ',', '.')
  || ' đ'
where trim(coalesce(quote_name,'')) = '';

create index if not exists quote_history_quote_name_idx
  on public.quote_history(lower(quote_name));

-- Xóa đúng chữ ký hiện hành trước khi thay đổi kiểu dữ liệu trả về.
drop function if exists public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb);
drop function if exists public.employee_list_quotes(uuid,text);
drop function if exists public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric);
drop function if exists public.admin_list_quote_history(uuid,text);

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
returns table(quote_code text, quote_name text)
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  v_user_id uuid;
  v_username text;
  v_code text;
  v_customer_name text;
  v_quote_name text;
  v_total numeric;
begin
  select u.id,u.username into v_user_id,v_username
  from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active
  limit 1;

  if v_user_id is null then
    raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn';
  end if;

  if jsonb_typeof(coalesce(p_items,'[]'::jsonb))<>'array'
     or jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then
    raise exception 'Báo giá chưa có sản phẩm';
  end if;

  v_customer_name := trim(coalesce(p_customer_name,''));
  v_total := greatest(coalesce(p_total,0),0);
  v_quote_name := coalesce(nullif(v_customer_name,''),'Khách lẻ')
    || ' - '
    || replace(to_char(round(v_total), 'FM999,999,999,999,990'), ',', '.')
    || ' đ';
  v_code := 'BG-'||to_char(clock_timestamp(),'YYYYMMDD-HH24MISS')||'-'||upper(substr(replace(extensions.gen_random_uuid()::text,'-',''),1,4));

  insert into public.quote_history(
    quote_code,quote_name,employee_id,employee_username,customer_name,
    customer_phone,customer_address,customer_note,items,total,quote_settings
  ) values (
    v_code,v_quote_name,v_user_id,v_username,v_customer_name,
    trim(coalesce(p_customer_phone,'')),trim(coalesce(p_customer_address,'')),
    trim(coalesce(p_customer_note,'')),p_items,v_total,coalesce(p_quote_settings,'{}'::jsonb)
  );

  return query select v_code,v_quote_name;
end
$$;

create function public.employee_list_quotes(p_token uuid,p_search text default null)
returns table(
  id uuid,quote_code text,quote_name text,customer_name text,customer_phone text,
  customer_address text,customer_note text,total numeric,created_at timestamptz,
  updated_at timestamptz,items jsonb
)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_user_id uuid;
  v_search text:=lower(trim(coalesce(p_search,'')));
begin
  select s.user_id into v_user_id
  from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active
  limit 1;

  if v_user_id is null then
    raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn';
  end if;

  return query
  select q.id,q.quote_code,q.quote_name,q.customer_name,q.customer_phone,
         q.customer_address,q.customer_note,q.total,q.created_at,q.updated_at,q.items
  from public.quote_history q
  where q.employee_id=v_user_id
    and (
      v_search=''
      or lower(q.quote_name) like '%'||v_search||'%'
      or lower(q.customer_name) like '%'||v_search||'%'
      or lower(q.customer_phone) like '%'||v_search||'%'
      or lower(q.quote_code) like '%'||v_search||'%'
    )
  order by q.created_at desc;
end
$$;

create function public.employee_update_quote(
  p_token uuid,p_quote_id uuid,p_customer_name text,p_customer_phone text,
  p_customer_address text,p_customer_note text,p_items jsonb,p_total numeric
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_user_id uuid;
  v_customer_name text;
  v_total numeric;
  v_quote_name text;
begin
  select s.user_id into v_user_id
  from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active
  limit 1;

  if v_user_id is null then
    raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn';
  end if;

  if jsonb_typeof(coalesce(p_items,'[]'::jsonb))<>'array'
     or jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then
    raise exception 'Báo giá chưa có sản phẩm';
  end if;

  v_customer_name := trim(coalesce(p_customer_name,''));
  v_total := greatest(coalesce(p_total,0),0);
  v_quote_name := coalesce(nullif(v_customer_name,''),'Khách lẻ')
    || ' - '
    || replace(to_char(round(v_total), 'FM999,999,999,999,990'), ',', '.')
    || ' đ';

  update public.quote_history
  set quote_name=v_quote_name,
      customer_name=v_customer_name,
      customer_phone=trim(coalesce(p_customer_phone,'')),
      customer_address=trim(coalesce(p_customer_address,'')),
      customer_note=trim(coalesce(p_customer_note,'')),
      items=p_items,total=v_total,updated_at=now()
  where id=p_quote_id and employee_id=v_user_id;

  if not found then
    raise exception 'Không tìm thấy báo giá hoặc bạn không có quyền sửa';
  end if;
end
$$;

create function public.admin_list_quote_history(p_token uuid,p_search text default null)
returns table(
  id uuid,quote_code text,quote_name text,employee_username text,customer_name text,
  customer_phone text,customer_address text,customer_note text,total numeric,
  created_at timestamptz,updated_at timestamptz,items jsonb
)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_search text:=lower(trim(coalesce(p_search,'')));
begin
  if not public.is_valid_admin(p_token) then
    raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn';
  end if;

  return query
  select q.id,q.quote_code,q.quote_name,q.employee_username,q.customer_name,
         q.customer_phone,q.customer_address,q.customer_note,q.total,
         q.created_at,q.updated_at,q.items
  from public.quote_history q
  where v_search=''
     or lower(q.quote_name) like '%'||v_search||'%'
     or lower(q.customer_name) like '%'||v_search||'%'
     or lower(q.customer_phone) like '%'||v_search||'%'
     or lower(q.quote_code) like '%'||v_search||'%'
     or lower(q.employee_username) like '%'||v_search||'%'
  order by q.created_at desc;
end
$$;

revoke all on function public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb) from public;
revoke all on function public.employee_list_quotes(uuid,text) from public;
revoke all on function public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric) from public;
revoke all on function public.admin_list_quote_history(uuid,text) from public;

grant execute on function public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb) to anon,authenticated;
grant execute on function public.employee_list_quotes(uuid,text) to anon,authenticated;
grant execute on function public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric) to anon,authenticated;
grant execute on function public.admin_list_quote_history(uuid,text) to anon,authenticated;

create table if not exists public.app_schema_version(
  version text primary key,
  applied_at timestamptz not null default now(),
  note text not null default ''
);
insert into public.app_schema_version(version,note)
values('2.0.8','Named saved quotes and optional customer name')
on conflict(version) do update set applied_at=now(),note=excluded.note;

commit;
notify pgrst,'reload schema';
