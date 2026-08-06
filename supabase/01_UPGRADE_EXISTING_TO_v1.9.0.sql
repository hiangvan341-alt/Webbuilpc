begin;

create extension if not exists pgcrypto with schema extensions;

-- Module 40: sample configurations
create table if not exists public.sample_configs(
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  items jsonb not null default '[]'::jsonb,
  total numeric(16,2) not null default 0,
  is_active boolean not null default true,
  created_by uuid references public.admin_accounts(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.sample_configs enable row level security;

-- Module 50: order requests
create table if not exists public.order_requests(
  id uuid primary key default gen_random_uuid(),
  request_code text not null unique,
  employee_id uuid references public.user_accounts(id) on delete set null,
  employee_username text not null default '',
  customer_name text not null,
  customer_phone text not null,
  customer_address text not null default '',
  customer_note text not null default '',
  items jsonb not null default '[]'::jsonb,
  total numeric(16,2) not null default 0,
  status text not null default 'new' check(status in ('new','contacted','completed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists order_requests_created_idx on public.order_requests(created_at desc);
create index if not exists order_requests_status_idx on public.order_requests(status,created_at desc);
alter table public.order_requests enable row level security;

-- Remove only current signatures before recreation.
drop function if exists public.public_list_sample_configs();
drop function if exists public.admin_list_sample_configs(uuid);
drop function if exists public.admin_save_sample_config(uuid,text,text,jsonb,numeric);
drop function if exists public.admin_delete_sample_config(uuid,uuid);
drop function if exists public.create_order_request(uuid,text,text,text,text,jsonb,numeric);
drop function if exists public.admin_list_order_requests(uuid,text);
drop function if exists public.admin_update_order_request_status(uuid,uuid,text);

create function public.public_list_sample_configs()
returns table(id uuid,name text,description text,total numeric,items jsonb,is_active boolean,created_at timestamptz)
language sql security definer set search_path=public
as $$ select s.id,s.name,s.description,s.total,s.items,s.is_active,s.created_at from public.sample_configs s where s.is_active order by s.created_at desc $$;

create function public.admin_list_sample_configs(p_token uuid)
returns table(id uuid,name text,description text,total numeric,items jsonb,is_active boolean,created_at timestamptz)
language plpgsql security definer set search_path=public
as $$ begin if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if; return query select s.id,s.name,s.description,s.total,s.items,s.is_active,s.created_at from public.sample_configs s order by s.created_at desc; end $$;

create function public.admin_save_sample_config(p_token uuid,p_name text,p_description text,p_items jsonb,p_total numeric)
returns uuid language plpgsql security definer set search_path=public
as $$ declare v_admin uuid; v_id uuid; begin
 select admin_id into v_admin from public.admin_sessions where token=p_token and expires_at>now() limit 1;
 if v_admin is null then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
 if length(trim(p_name))<2 then raise exception 'Tên cấu hình mẫu quá ngắn'; end if;
 if jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'Cấu hình mẫu chưa có linh kiện'; end if;
 insert into public.sample_configs(name,description,items,total,created_by) values(trim(p_name),trim(coalesce(p_description,'')),coalesce(p_items,'[]'::jsonb),greatest(coalesce(p_total,0),0),v_admin) returning id into v_id;
 return v_id; end $$;

create function public.admin_delete_sample_config(p_token uuid,p_config_id uuid)
returns void language plpgsql security definer set search_path=public
as $$ begin if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if; delete from public.sample_configs where id=p_config_id; end $$;

create function public.create_order_request(p_token uuid,p_customer_name text,p_customer_phone text,p_customer_address text,p_customer_note text,p_items jsonb,p_total numeric)
returns table(request_code text)
language plpgsql security definer set search_path=public
as $$ declare v_user uuid; v_username text:=''; v_code text; begin
 if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'Vui lòng nhập tên khách hàng'; end if;
 if length(trim(coalesce(p_customer_phone,'')))<6 then raise exception 'Vui lòng nhập số điện thoại hợp lệ'; end if;
 if jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'Chưa chọn sản phẩm'; end if;
 if p_token is not null then select s.user_id,u.username into v_user,v_username from public.user_sessions s join public.user_accounts u on u.id=s.user_id where s.token=p_token and s.expires_at>now() and u.is_active limit 1; end if;
 v_code:='DH-'||to_char(now(),'YYYYMMDD-HH24MISS')||'-'||upper(substr(encode(gen_random_bytes(2),'hex'),1,4));
 insert into public.order_requests(request_code,employee_id,employee_username,customer_name,customer_phone,customer_address,customer_note,items,total)
 values(v_code,v_user,coalesce(v_username,''),trim(p_customer_name),trim(p_customer_phone),trim(coalesce(p_customer_address,'')),trim(coalesce(p_customer_note,'')),p_items,greatest(coalesce(p_total,0),0));
 return query select v_code; end $$;

create function public.admin_list_order_requests(p_token uuid,p_search text default null)
returns table(id uuid,request_code text,employee_username text,customer_name text,customer_phone text,customer_address text,customer_note text,total numeric,status text,items jsonb,created_at timestamptz)
language plpgsql security definer set search_path=public
as $$ declare v text:=lower(trim(coalesce(p_search,''))); begin
 if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
 return query select o.id,o.request_code,o.employee_username,o.customer_name,o.customer_phone,o.customer_address,o.customer_note,o.total,o.status,o.items,o.created_at from public.order_requests o
 where v='' or lower(o.request_code) like '%'||v||'%' or lower(o.employee_username) like '%'||v||'%' or lower(o.customer_name) like '%'||v||'%' or lower(o.customer_phone) like '%'||v||'%'
 order by o.created_at desc; end $$;

create function public.admin_update_order_request_status(p_token uuid,p_request_id uuid,p_status text)
returns void language plpgsql security definer set search_path=public
as $$ begin if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if; if p_status not in ('new','contacted','completed','cancelled') then raise exception 'Trạng thái không hợp lệ'; end if; update public.order_requests set status=p_status,updated_at=now() where id=p_request_id; end $$;

revoke all on function public.public_list_sample_configs() from public;
revoke all on function public.admin_list_sample_configs(uuid) from public;
revoke all on function public.admin_save_sample_config(uuid,text,text,jsonb,numeric) from public;
revoke all on function public.admin_delete_sample_config(uuid,uuid) from public;
revoke all on function public.create_order_request(uuid,text,text,text,text,jsonb,numeric) from public;
revoke all on function public.admin_list_order_requests(uuid,text) from public;
revoke all on function public.admin_update_order_request_status(uuid,uuid,text) from public;
grant execute on function public.public_list_sample_configs() to anon,authenticated;
grant execute on function public.admin_list_sample_configs(uuid) to anon,authenticated;
grant execute on function public.admin_save_sample_config(uuid,text,text,jsonb,numeric) to anon,authenticated;
grant execute on function public.admin_delete_sample_config(uuid,uuid) to anon,authenticated;
grant execute on function public.create_order_request(uuid,text,text,text,text,jsonb,numeric) to anon,authenticated;
grant execute on function public.admin_list_order_requests(uuid,text) to anon,authenticated;
grant execute on function public.admin_update_order_request_status(uuid,uuid,text) to anon,authenticated;

create table if not exists public.app_schema_version(version text primary key,applied_at timestamptz not null default now(),note text not null default '');
insert into public.app_schema_version(version,note) values('1.9.0','Sample configurations, partial builds, order requests and modular Admin tabs') on conflict(version) do update set applied_at=now(),note=excluded.note;
notify pgrst,'reload schema';
commit;
