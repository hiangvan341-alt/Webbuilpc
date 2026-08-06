-- WEB BUILD PC v1.7.0 - CÀI MỚI HOÀN TOÀN
-- Chạy duy nhất file này cho Supabase project mới.

begin;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists unaccent;

do $$ begin
  create type public.product_category as enum ('cpu','mainboard','ram','gpu','ssd','psu','case','cooler','monitor','accessory');
exception when duplicate_object then null; end $$;
alter type public.product_category add value if not exists 'accessory';

create table if not exists public.products(
 id uuid primary key default extensions.gen_random_uuid(), category public.product_category not null,
 group_name text not null default '', name text not null, slug text unique not null, brand text not null default '',
 sku text unique, price bigint not null default 0 check(price>=0), sale_price bigint check(sale_price>=0),
 stock numeric not null default 0, warranty text not null default '', image_url text,
 specs jsonb not null default '{}'::jsonb, is_active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.pc_builds(
 id uuid primary key default extensions.gen_random_uuid(), user_id uuid references auth.users(id) on delete set null,
 name text not null default 'Cấu hình của tôi', share_code text unique not null default encode(extensions.gen_random_bytes(6),'hex'),
 items jsonb not null default '{}'::jsonb,total_price bigint not null default 0,customer_name text,customer_phone text,customer_note text,
 status text not null default 'draft' check(status in('draft','submitted','contacted','ordered','cancelled')),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);

create table if not exists public.admin_accounts(
 id uuid primary key default extensions.gen_random_uuid(),username text not null,
 password_hash text not null,is_active boolean not null default true,created_at timestamptz not null default now()
);
create unique index if not exists admin_accounts_username_normalized_uidx on public.admin_accounts((lower(trim(username))));

create table if not exists public.admin_sessions(
 token uuid primary key default extensions.gen_random_uuid(),admin_id uuid not null references public.admin_accounts(id) on delete cascade,
 expires_at timestamptz not null default now()+interval '12 hours',created_at timestamptz not null default now()
);

insert into public.admin_accounts(username,password_hash,is_active)
values('admin',extensions.crypt('Do12345',extensions.gen_salt('bf',12)),true)
on conflict do nothing;

create or replace function public.is_valid_admin(p_token uuid)
returns boolean language sql security definer set search_path=public
as $$select exists(select 1 from public.admin_sessions s join public.admin_accounts a on a.id=s.admin_id where s.token=p_token and s.expires_at>now() and a.is_active)$$;

create or replace function public.admin_login(p_username text,p_password text)
returns table(token uuid) language plpgsql security definer set search_path=public,extensions
as $$declare v_admin uuid;v_token uuid;begin
 select a.id into v_admin from public.admin_accounts a where lower(trim(a.username))=lower(trim(coalesce(p_username,''))) and a.is_active and a.password_hash=extensions.crypt(coalesce(p_password,''),a.password_hash) limit 1;
 if v_admin is null then raise exception 'Sai tài khoản hoặc mật khẩu';end if;
 delete from public.admin_sessions where expires_at<now();
 insert into public.admin_sessions(admin_id) values(v_admin) returning admin_sessions.token into v_token;
 return query select v_token;end$$;

create or replace function public.admin_create_account(p_token uuid,p_username text,p_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$declare v_username text:=lower(trim(coalesce(p_username,'')));begin
 if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ';end if;
 if v_username !~ '^[a-z0-9_.-]{3,40}$' then raise exception 'Tên tài khoản không hợp lệ';end if;
 if length(coalesce(p_password,''))<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự';end if;
 insert into public.admin_accounts(username,password_hash) values(v_username,extensions.crypt(p_password,extensions.gen_salt('bf',12)));
exception when unique_violation then raise exception 'Tên tài khoản admin đã tồn tại';end$$;

create or replace function public.slugify_product(p_name text)
returns text language sql immutable set search_path=public
as $$select lower(regexp_replace(public.unaccent(trim(p_name)),'[^a-zA-Z0-9]+','-','g'))$$;

create or replace function public.admin_import_products(p_token uuid,p_rows jsonb)
returns integer language plpgsql security definer set search_path=public
as $$declare r jsonb;n integer:=0;base_slug text;final_slug text;begin
 if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ';end if;
 if jsonb_typeof(p_rows)<>'array' then raise exception 'Dữ liệu Excel không hợp lệ';end if;
 for r in select * from jsonb_array_elements(p_rows) loop
  if nullif(trim(r->>'name'),'') is null then continue;end if;
  base_slug:=public.slugify_product(r->>'name');final_slug:=base_slug||'-'||substr(md5(coalesce(r->>'group_name','')||'|'||(r->>'name')),1,10);
  insert into public.products(category,group_name,name,brand,slug,price,stock,warranty,is_active,updated_at)
  values((r->>'category')::public.product_category,coalesce(r->>'group_name',''),r->>'name',coalesce(r->>'brand',''),final_slug,greatest(0,coalesce((r->>'price')::numeric,0)),coalesce((r->>'stock')::numeric,0),coalesce(r->>'warranty',''),true,now())
  on conflict(slug) do update set category=excluded.category,group_name=excluded.group_name,name=excluded.name,brand=excluded.brand,price=excluded.price,stock=excluded.stock,warranty=excluded.warranty,is_active=true,updated_at=now();n:=n+1;
 end loop;return n;end$$;

create table if not exists public.quote_settings(
 id smallint primary key default 1 check(id=1),company_name text not null,hotline text not null,email text not null,address text not null,
 website text not null default '',notice text not null default '',thank_you text not null default '',updated_at timestamptz not null default now()
);
insert into public.quote_settings(id,company_name,hotline,email,address,website,notice,thank_you)
values(1,'CÔNG TY TNHH CÔNG NGHỆ NOVA TECH PC','0377 455 855','contact@novatechpc.vn','134 Nguyễn Chính - Hoàng Mai - HN','Novatechpc.vn','Giá bán, khuyến mãi của sản phẩm và tình trạng còn hàng có thể thay đổi bất cứ lúc nào mà không kịp báo trước.','NOVA TECH PC CHÂN THÀNH CẢM ƠN QUÝ KHÁCH') on conflict(id) do nothing;

create or replace function public.get_quote_settings()
returns table(company_name text,hotline text,email text,address text,website text,notice text,thank_you text)
language sql security definer set search_path=public as $$select q.company_name,q.hotline,q.email,q.address,q.website,q.notice,q.thank_you from public.quote_settings q where id=1$$;

create or replace function public.admin_update_quote_settings(p_token uuid,p_settings jsonb)
returns void language plpgsql security definer set search_path=public as $$begin
 if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ';end if;
 update public.quote_settings set company_name=coalesce(nullif(trim(p_settings->>'company_name'),''),company_name),hotline=coalesce(p_settings->>'hotline',hotline),email=coalesce(p_settings->>'email',email),address=coalesce(p_settings->>'address',address),website=coalesce(p_settings->>'website',website),notice=coalesce(p_settings->>'notice',notice),thank_you=coalesce(p_settings->>'thank_you',thank_you),updated_at=now() where id=1;end$$;

-- Module user chuẩn v1.6.0 được nhúng bên dưới.
-- MODULE 20: Tài khoản người dùng - nguồn chuẩn v1.6.0
-- Có thể chạy lặp lại. Không xóa user hiện có.

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.user_accounts (
  id uuid primary key default extensions.gen_random_uuid(),
  username text not null,
  password_hash text not null,
  is_active boolean not null default true,
  created_by uuid,
  password_changed_at timestamptz,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_accounts add column if not exists created_by uuid;
alter table public.user_accounts add column if not exists password_changed_at timestamptz;
alter table public.user_accounts add column if not exists last_login_at timestamptz;
alter table public.user_accounts add column if not exists created_at timestamptz not null default now();
alter table public.user_accounts add column if not exists updated_at timestamptz not null default now();

create table if not exists public.user_sessions (
  token uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '30 days',
  created_at timestamptz not null default now()
);

-- Thêm FK created_by nếu bảng admin đã tồn tại và constraint chưa có.
do $$
begin
  if to_regclass('public.admin_accounts') is not null
     and not exists (
       select 1 from pg_constraint
       where conrelid='public.user_accounts'::regclass
         and conname='user_accounts_created_by_fkey'
     ) then
    alter table public.user_accounts
      add constraint user_accounts_created_by_fkey
      foreign key(created_by) references public.admin_accounts(id) on delete set null;
  end if;
end $$;

-- Chuẩn hóa username mà không làm migration chết khi dữ liệu cũ trùng hoa/thường.
do $$
declare r record; v_base text; v_name text;
begin
  for r in
    select id, username,
           row_number() over(partition by lower(trim(username)) order by created_at nulls last, id) as rn
    from public.user_accounts
  loop
    v_base := lower(trim(coalesce(r.username,'')));
    if v_base = '' or v_base !~ '^[a-z0-9_.-]{3,40}$' then
      v_base := 'user_' || substr(replace(r.id::text,'-',''),1,8);
    end if;
    v_name := case when r.rn=1 then v_base
                   else left(v_base,28) || '_dup_' || substr(replace(r.id::text,'-',''),1,6) end;
    update public.user_accounts set username=v_name, updated_at=now() where id=r.id and username is distinct from v_name;
  end loop;
end $$;

drop index if exists public.user_accounts_username_normalized_uidx;
create unique index user_accounts_username_normalized_uidx
  on public.user_accounts ((lower(trim(username))));
create index if not exists user_sessions_user_id_idx on public.user_sessions(user_id);
create index if not exists user_sessions_expires_at_idx on public.user_sessions(expires_at);

alter table public.user_accounts enable row level security;
alter table public.user_sessions enable row level security;

-- Xóa đúng chữ ký cũ để không còn function chồng chéo.
drop function if exists public.admin_create_user_account(uuid,text,text);
drop function if exists public.admin_list_user_accounts(uuid);
drop function if exists public.admin_update_user_account(uuid,uuid,text,boolean);
drop function if exists public.admin_reset_user_password(uuid,uuid,text);
drop function if exists public.admin_delete_user_account(uuid,uuid);
drop function if exists public.user_login(text,text);

create function public.admin_create_user_account(p_token uuid,p_username text,p_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$
declare v_admin_id uuid; v_username text:=lower(trim(coalesce(p_username,''))); v_user_id uuid;
begin
  select s.admin_id into v_admin_id
  from public.admin_sessions s join public.admin_accounts a on a.id=s.admin_id
  where s.token=p_token and s.expires_at>now() and a.is_active limit 1;
  if v_admin_id is null then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  if v_username !~ '^[a-z0-9_.-]{3,40}$' then raise exception 'Tên tài khoản chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang; từ 3 đến 40 ký tự'; end if;
  if length(coalesce(p_password,''))<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;

  select id into v_user_id from public.user_accounts where lower(trim(username))=v_username limit 1;
  if v_user_id is null then
    insert into public.user_accounts(username,password_hash,is_active,created_by,password_changed_at,updated_at)
    values(v_username,extensions.crypt(p_password,extensions.gen_salt('bf',12)),true,v_admin_id,now(),now());
  else
    update public.user_accounts set
      username=v_username,
      password_hash=extensions.crypt(p_password,extensions.gen_salt('bf',12)),
      is_active=true, created_by=v_admin_id, password_changed_at=now(), updated_at=now()
    where id=v_user_id;
    delete from public.user_sessions where user_id=v_user_id;
  end if;
end $$;

create function public.admin_list_user_accounts(p_token uuid)
returns table(id uuid,username text,is_active boolean,password_ready boolean,created_at timestamptz,last_login_at timestamptz)
language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  return query
  select u.id,u.username,u.is_active,
         (u.password_hash ~ '^[$]2[aby][$][0-9]{2}[$]') as password_ready,
         u.created_at,u.last_login_at
  from public.user_accounts u order by u.created_at desc,u.username;
end $$;

create function public.admin_update_user_account(p_token uuid,p_user_id uuid,p_username text default null,p_is_active boolean default null)
returns void language plpgsql security definer set search_path=public
as $$
declare v_username text;
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  if not exists(select 1 from public.user_accounts where id=p_user_id) then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
  v_username:=case when p_username is null then null else lower(trim(p_username)) end;
  if v_username is not null and v_username !~ '^[a-z0-9_.-]{3,40}$' then raise exception 'Tên tài khoản không hợp lệ'; end if;
  update public.user_accounts set username=coalesce(v_username,username),is_active=coalesce(p_is_active,is_active),updated_at=now() where id=p_user_id;
  if p_is_active=false then delete from public.user_sessions where user_id=p_user_id; end if;
exception when unique_violation then
  raise exception 'Tên tài khoản đã tồn tại';
end $$;

create function public.admin_reset_user_password(p_token uuid,p_user_id uuid,p_new_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  if length(coalesce(p_new_password,''))<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;
  update public.user_accounts set
    password_hash=extensions.crypt(p_new_password,extensions.gen_salt('bf',12)),
    password_changed_at=now(),is_active=true,updated_at=now()
  where id=p_user_id;
  if not found then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
  delete from public.user_sessions where user_id=p_user_id;
end $$;

create function public.admin_delete_user_account(p_token uuid,p_user_id uuid)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  delete from public.user_accounts where id=p_user_id;
  if not found then raise exception 'Không tìm thấy tài khoản người dùng'; end if;
end $$;

create function public.user_login(p_username text,p_password text)
returns table(token uuid)
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
  return query select v_token;
end $$;

revoke all on function public.admin_create_user_account(uuid,text,text) from public;
revoke all on function public.admin_list_user_accounts(uuid) from public;
revoke all on function public.admin_update_user_account(uuid,uuid,text,boolean) from public;
revoke all on function public.admin_reset_user_password(uuid,uuid,text) from public;
revoke all on function public.admin_delete_user_account(uuid,uuid) from public;
revoke all on function public.user_login(text,text) from public;
grant execute on function public.admin_create_user_account(uuid,text,text) to anon,authenticated;
grant execute on function public.admin_list_user_accounts(uuid) to anon,authenticated;
grant execute on function public.admin_update_user_account(uuid,uuid,text,boolean) to anon,authenticated;
grant execute on function public.admin_reset_user_password(uuid,uuid,text) to anon,authenticated;
grant execute on function public.admin_delete_user_account(uuid,uuid) to anon,authenticated;
grant execute on function public.user_login(text,text) to anon,authenticated;

alter table public.products enable row level security;
alter table public.pc_builds enable row level security;
alter table public.admin_accounts enable row level security;
alter table public.admin_sessions enable row level security;
alter table public.quote_settings enable row level security;

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products" on public.products for select using(is_active=true);
drop policy if exists "Anyone can create build request" on public.pc_builds;
create policy "Anyone can create build request" on public.pc_builds for insert with check(true);
drop policy if exists "Public can read quote settings" on public.quote_settings;
create policy "Public can read quote settings" on public.quote_settings for select using(true);

create index if not exists products_category_idx on public.products(category);
create index if not exists products_active_idx on public.products(is_active);
create index if not exists products_group_idx on public.products(group_name);
create index if not exists pc_builds_share_code_idx on public.pc_builds(share_code);

revoke all on function public.admin_login(text,text) from public;
revoke all on function public.admin_create_account(uuid,text,text) from public;
revoke all on function public.admin_import_products(uuid,jsonb) from public;
revoke all on function public.get_quote_settings() from public;
revoke all on function public.admin_update_quote_settings(uuid,jsonb) from public;
grant execute on function public.admin_login(text,text) to anon,authenticated;
grant execute on function public.admin_create_account(uuid,text,text) to anon,authenticated;
grant execute on function public.admin_import_products(uuid,jsonb) to anon,authenticated;
grant execute on function public.get_quote_settings() to anon,authenticated;
grant execute on function public.admin_update_quote_settings(uuid,jsonb) to anon,authenticated;

create table if not exists public.app_schema_version(version text primary key,applied_at timestamptz not null default now(),note text not null default '');
insert into public.app_schema_version(version,note) values('1.7.0','Fresh canonical schema with employee quote history') on conflict(version) do update set applied_at=now(),note=excluded.note;
commit;
notify pgrst,'reload schema';
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

insert into public.app_schema_version(version,note) values('1.7.0','Employee quote history module') on conflict(version) do update set applied_at=now(),note=excluded.note;
notify pgrst,'reload schema';

-- =========================================================
-- CURRENT MODULE v1.8.0 (final override for fresh database)
-- =========================================================
-- MODULE 30 v1.8.0: LỊCH SỬ BÁO GIÁ
-- Có thể chạy lại an toàn. Không xóa dữ liệu hiện có.

begin;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.quote_history (
  id uuid primary key default extensions.gen_random_uuid(),
  quote_code text not null unique,
  employee_id uuid references public.user_accounts(id) on delete set null,
  employee_username text not null default '',
  customer_name text not null default '',
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

-- Xóa đúng chữ ký cũ trước khi tạo RPC hiện hành.
drop function if exists public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb);
drop function if exists public.employee_list_quotes(uuid,text);
drop function if exists public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric);
drop function if exists public.employee_delete_quote(uuid,uuid);
drop function if exists public.admin_list_quote_history(uuid,text);

create function public.employee_save_quote(
  p_token uuid,p_customer_name text,p_customer_phone text,p_customer_address text,
  p_customer_note text,p_items jsonb,p_total numeric,p_quote_settings jsonb
) returns table(quote_code text)
language plpgsql security definer set search_path=public,extensions as $$
declare v_user_id uuid; v_username text; v_code text;
begin
  select u.id,u.username into v_user_id,v_username
  from public.user_sessions s join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
  if v_user_id is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'Vui lòng nhập tên khách hàng'; end if;
  if jsonb_typeof(coalesce(p_items,'[]'::jsonb))<>'array' or jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'Báo giá chưa có sản phẩm'; end if;
  v_code := 'BG-'||to_char(clock_timestamp(),'YYYYMMDD-HH24MISS')||'-'||upper(substr(replace(extensions.gen_random_uuid()::text,'-',''),1,4));
  insert into public.quote_history(quote_code,employee_id,employee_username,customer_name,customer_phone,customer_address,customer_note,items,total,quote_settings)
  values(v_code,v_user_id,v_username,trim(p_customer_name),trim(coalesce(p_customer_phone,'')),trim(coalesce(p_customer_address,'')),trim(coalesce(p_customer_note,'')),p_items,greatest(coalesce(p_total,0),0),coalesce(p_quote_settings,'{}'::jsonb));
  return query select v_code;
end $$;

create function public.employee_list_quotes(p_token uuid,p_search text default null)
returns table(id uuid,quote_code text,customer_name text,customer_phone text,customer_address text,customer_note text,total numeric,created_at timestamptz,updated_at timestamptz,items jsonb)
language plpgsql security definer set search_path=public as $$
declare v_user_id uuid; v_search text:=lower(trim(coalesce(p_search,'')));
begin
  select s.user_id into v_user_id from public.user_sessions s join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
  if v_user_id is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  return query select q.id,q.quote_code,q.customer_name,q.customer_phone,q.customer_address,q.customer_note,q.total,q.created_at,q.updated_at,q.items
  from public.quote_history q where q.employee_id=v_user_id and
  (v_search='' or lower(q.customer_name) like '%'||v_search||'%' or lower(q.customer_phone) like '%'||v_search||'%' or lower(q.quote_code) like '%'||v_search||'%')
  order by q.created_at desc;
end $$;

create function public.employee_update_quote(
  p_token uuid,p_quote_id uuid,p_customer_name text,p_customer_phone text,
  p_customer_address text,p_customer_note text,p_items jsonb,p_total numeric
) returns void language plpgsql security definer set search_path=public as $$
declare v_user_id uuid;
begin
  select s.user_id into v_user_id from public.user_sessions s join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
  if v_user_id is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  if length(trim(coalesce(p_customer_name,'')))<2 then raise exception 'Vui lòng nhập tên khách hàng'; end if;
  if jsonb_typeof(coalesce(p_items,'[]'::jsonb))<>'array' or jsonb_array_length(coalesce(p_items,'[]'::jsonb))=0 then raise exception 'Báo giá chưa có sản phẩm'; end if;
  update public.quote_history set customer_name=trim(p_customer_name),customer_phone=trim(coalesce(p_customer_phone,'')),
    customer_address=trim(coalesce(p_customer_address,'')),customer_note=trim(coalesce(p_customer_note,'')),
    items=p_items,total=greatest(coalesce(p_total,0),0),updated_at=now()
  where id=p_quote_id and employee_id=v_user_id;
  if not found then raise exception 'Không tìm thấy báo giá hoặc bạn không có quyền sửa'; end if;
end $$;

create function public.employee_delete_quote(p_token uuid,p_quote_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare v_user_id uuid;
begin
  select s.user_id into v_user_id from public.user_sessions s join public.user_accounts u on u.id=s.user_id
  where s.token=p_token and s.expires_at>now() and u.is_active limit 1;
  if v_user_id is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  delete from public.quote_history where id=p_quote_id and employee_id=v_user_id;
  if not found then raise exception 'Không tìm thấy báo giá hoặc bạn không có quyền xóa'; end if;
end $$;

create function public.admin_list_quote_history(p_token uuid,p_search text default null)
returns table(id uuid,quote_code text,employee_username text,customer_name text,customer_phone text,customer_address text,customer_note text,total numeric,created_at timestamptz,updated_at timestamptz,items jsonb)
language plpgsql security definer set search_path=public as $$
declare v_search text:=lower(trim(coalesce(p_search,'')));
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  return query select q.id,q.quote_code,q.employee_username,q.customer_name,q.customer_phone,q.customer_address,q.customer_note,q.total,q.created_at,q.updated_at,q.items
  from public.quote_history q where v_search='' or lower(q.customer_name) like '%'||v_search||'%' or lower(q.customer_phone) like '%'||v_search||'%' or lower(q.quote_code) like '%'||v_search||'%' or lower(q.employee_username) like '%'||v_search||'%'
  order by q.created_at desc;
end $$;

revoke all on function public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb) from public;
revoke all on function public.employee_list_quotes(uuid,text) from public;
revoke all on function public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric) from public;
revoke all on function public.employee_delete_quote(uuid,uuid) from public;
revoke all on function public.admin_list_quote_history(uuid,text) from public;
grant execute on function public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb) to anon,authenticated;
grant execute on function public.employee_list_quotes(uuid,text) to anon,authenticated;
grant execute on function public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric) to anon,authenticated;
grant execute on function public.employee_delete_quote(uuid,uuid) to anon,authenticated;
grant execute on function public.admin_list_quote_history(uuid,text) to anon,authenticated;

create table if not exists public.app_schema_version(version text primary key,applied_at timestamptz not null default now(),note text not null default '');
insert into public.app_schema_version(version,note) values('1.8.0','Quote view, update, delete and admin-wide history')
on conflict(version) do update set applied_at=now(),note=excluded.note;
commit;
notify pgrst,'reload schema';
