create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
alter extension pgcrypto set schema extensions;
create extension if not exists unaccent;

-- Danh mục mở rộng để nhận được cả phụ kiện từ file Excel.
do $$ begin
  create type public.product_category as enum ('cpu','mainboard','ram','gpu','ssd','psu','case','cooler','monitor','accessory');
exception when duplicate_object then null;
end $$;
alter type public.product_category add value if not exists 'accessory';

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category public.product_category not null,
  group_name text not null default '',
  name text not null,
  slug text unique not null,
  brand text not null default '',
  sku text unique,
  price bigint not null check (price >= 0),
  sale_price bigint check (sale_price >= 0),
  stock numeric not null default 0,
  warranty text not null default '',
  image_url text,
  specs jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products add column if not exists group_name text not null default '';
alter table public.products add column if not exists warranty text not null default '';

create table if not exists public.pc_builds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  name text not null default 'Cấu hình của tôi',
  share_code text unique not null default encode(gen_random_bytes(6), 'hex'),
  items jsonb not null default '{}'::jsonb,
  total_price bigint not null default 0,
  customer_name text,
  customer_phone text,
  customer_note text,
  status text not null default 'draft' check (status in ('draft','submitted','contacted','ordered','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Tài khoản quản trị riêng. Mật khẩu chỉ lưu dưới dạng bcrypt hash.
create table if not exists public.admin_accounts (
  id uuid primary key default gen_random_uuid(),
  username text unique not null check (username ~ '^[A-Za-z0-9_.-]{3,40}$'),
  password_hash text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_sessions (
  token uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admin_accounts(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '12 hours',
  created_at timestamptz not null default now()
);

insert into public.admin_accounts(username,password_hash)
values ('admin', extensions.crypt('Do12345', extensions.gen_salt('bf', 12)))
on conflict (username) do nothing;

alter table public.products enable row level security;
alter table public.pc_builds enable row level security;
alter table public.admin_accounts enable row level security;
alter table public.admin_sessions enable row level security;

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products" on public.products for select using (is_active = true);
drop policy if exists "Users can read own builds" on public.pc_builds;
create policy "Users can read own builds" on public.pc_builds for select using (auth.uid() = user_id or user_id is null);
drop policy if exists "Anyone can create build request" on public.pc_builds;
create policy "Anyone can create build request" on public.pc_builds for insert with check (true);
drop policy if exists "Users can update own builds" on public.pc_builds;
create policy "Users can update own builds" on public.pc_builds for update using (auth.uid() = user_id);

create or replace function public.admin_login(p_username text, p_password text)
returns table(token uuid)
language plpgsql security definer set search_path=public
as $$
declare v_admin uuid; v_token uuid;
begin
  select id into v_admin from admin_accounts
  where lower(username)=lower(trim(p_username)) and is_active and password_hash=extensions.crypt(p_password,password_hash);
  if v_admin is null then raise exception 'Sai tài khoản hoặc mật khẩu'; end if;
  delete from admin_sessions where expires_at < now();
  insert into admin_sessions(admin_id) values(v_admin) returning admin_sessions.token into v_token;
  return query select v_token;
end $$;

create or replace function public.is_valid_admin(p_token uuid)
returns boolean language sql security definer set search_path=public
as $$ select exists(select 1 from admin_sessions s join admin_accounts a on a.id=s.admin_id where s.token=p_token and s.expires_at>now() and a.is_active) $$;

create or replace function public.admin_create_account(p_token uuid, p_username text, p_password text)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if not is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if length(trim(p_password)) < 6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;
  insert into admin_accounts(username,password_hash) values(trim(p_username),extensions.crypt(p_password,extensions.gen_salt('bf',12)));
end $$;

create or replace function public.slugify_product(p_name text)
returns text language sql immutable
as $$ select lower(regexp_replace(unaccent(trim(p_name)), '[^a-zA-Z0-9]+', '-', 'g')) $$;

create or replace function public.admin_import_products(p_token uuid, p_rows jsonb)
returns integer language plpgsql security definer set search_path=public
as $$
declare r jsonb; n integer:=0; base_slug text; final_slug text;
begin
  if not is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if jsonb_typeof(p_rows) <> 'array' then raise exception 'Dữ liệu Excel không hợp lệ'; end if;
  for r in select * from jsonb_array_elements(p_rows) loop
    if nullif(trim(r->>'name'),'') is null then continue; end if;
    base_slug := slugify_product(r->>'name');
    final_slug := base_slug || '-' || substr(md5(coalesce(r->>'group_name','') || '|' || (r->>'name')),1,10);
    insert into products(category,group_name,name,brand,slug,price,stock,warranty,is_active,updated_at)
    values ((r->>'category')::product_category,coalesce(r->>'group_name',''),r->>'name',coalesce(r->>'brand',''),final_slug,greatest(0,coalesce((r->>'price')::numeric,0)),coalesce((r->>'stock')::numeric,0),coalesce(r->>'warranty',''),true,now())
    on conflict (slug) do update set category=excluded.category,group_name=excluded.group_name,name=excluded.name,brand=excluded.brand,price=excluded.price,stock=excluded.stock,warranty=excluded.warranty,is_active=true,updated_at=now();
    n:=n+1;
  end loop;
  return n;
end $$;

grant execute on function public.admin_login(text,text) to anon,authenticated;
grant execute on function public.admin_create_account(uuid,text,text) to anon,authenticated;
grant execute on function public.admin_import_products(uuid,jsonb) to anon,authenticated;

create index if not exists products_category_idx on public.products(category);
create index if not exists products_active_idx on public.products(is_active);
create index if not exists products_group_idx on public.products(group_name);
create index if not exists pc_builds_share_code_idx on public.pc_builds(share_code);

-- =========================================================
-- v1.3.0: tài khoản người dùng và mẫu báo giá tùy chỉnh
-- =========================================================
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
alter extension pgcrypto set schema extensions;

-- Sửa các hàm quản trị để luôn gọi đúng schema pgcrypto.
create or replace function public.admin_login(p_username text, p_password text)
returns table(token uuid)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_admin uuid; v_token uuid;
begin
  select id into v_admin from public.admin_accounts
  where lower(username)=lower(trim(p_username)) and is_active
    and password_hash=extensions.crypt(p_password,password_hash);
  if v_admin is null then raise exception 'Sai tài khoản hoặc mật khẩu'; end if;
  delete from public.admin_sessions where expires_at < now();
  insert into public.admin_sessions(admin_id) values(v_admin) returning admin_sessions.token into v_token;
  return query select v_token;
end $$;

create or replace function public.admin_create_account(p_token uuid, p_username text, p_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if length(trim(p_password)) < 6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;
  insert into public.admin_accounts(username,password_hash)
  values(trim(p_username),extensions.crypt(p_password,extensions.gen_salt('bf',12)));
end $$;

-- Tài khoản người dùng riêng, không lưu mật khẩu dạng rõ.
create table if not exists public.user_accounts (
  id uuid primary key default gen_random_uuid(),
  username text unique not null check (username ~ '^[A-Za-z0-9_.-]{3,40}$'),
  password_hash text not null,
  is_active boolean not null default true,
  created_by uuid references public.admin_accounts(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.user_sessions (
  token uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  expires_at timestamptz not null default now() + interval '30 days',
  created_at timestamptz not null default now()
);
alter table public.user_accounts enable row level security;
alter table public.user_sessions enable row level security;

create or replace function public.admin_create_user_account(p_token uuid,p_username text,p_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$
declare v_admin uuid;
begin
  select s.admin_id into v_admin from public.admin_sessions s where s.token=p_token and s.expires_at>now();
  if v_admin is null then raise exception 'Phiên quản trị không hợp lệ'; end if;
  if length(trim(p_username))<3 then raise exception 'Tên tài khoản phải có ít nhất 3 ký tự'; end if;
  if length(p_password)<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự'; end if;
  insert into public.user_accounts(username,password_hash,created_by)
  values(trim(p_username),extensions.crypt(p_password,extensions.gen_salt('bf',12)),v_admin);
end $$;

create or replace function public.user_login(p_username text,p_password text)
returns table(token uuid)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_user uuid; v_token uuid;
begin
  select id into v_user from public.user_accounts
  where lower(username)=lower(trim(p_username)) and is_active
    and password_hash=extensions.crypt(p_password,password_hash);
  if v_user is null then raise exception 'Sai tài khoản hoặc mật khẩu'; end if;
  delete from public.user_sessions where expires_at<now();
  insert into public.user_sessions(user_id) values(v_user) returning user_sessions.token into v_token;
  return query select v_token;
end $$;

-- Một dòng cấu hình báo giá dùng chung toàn website.
create table if not exists public.quote_settings (
  id smallint primary key default 1 check(id=1),
  company_name text not null,
  hotline text not null,
  email text not null,
  address text not null,
  website text not null default '',
  notice text not null default '',
  thank_you text not null default '',
  updated_at timestamptz not null default now()
);
insert into public.quote_settings(id,company_name,hotline,email,address,website,notice,thank_you)
values(1,'CÔNG TY TNHH CÔNG NGHỆ NOVA TECH PC','0377 455 855','contact@novatechpc.vn','134 Nguyễn Chính - Hoàng Mai - HN','Novatechpc.vn','Giá bán, khuyến mãi của sản phẩm và tình trạng còn hàng có thể thay đổi bất cứ lúc nào mà không kịp báo trước.','NOVA TECH PC CHÂN THÀNH CẢM ƠN QUÝ KHÁCH')
on conflict(id) do nothing;
alter table public.quote_settings enable row level security;
drop policy if exists "Public can read quote settings" on public.quote_settings;
create policy "Public can read quote settings" on public.quote_settings for select using(true);

create or replace function public.get_quote_settings()
returns table(company_name text,hotline text,email text,address text,website text,notice text,thank_you text)
language sql security definer set search_path=public
as $$ select q.company_name,q.hotline,q.email,q.address,q.website,q.notice,q.thank_you from public.quote_settings q where id=1 $$;

create or replace function public.admin_update_quote_settings(p_token uuid,p_settings jsonb)
returns void language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ'; end if;
  update public.quote_settings set
    company_name=coalesce(nullif(trim(p_settings->>'company_name'),''),company_name),
    hotline=coalesce(p_settings->>'hotline',hotline),
    email=coalesce(p_settings->>'email',email),
    address=coalesce(p_settings->>'address',address),
    website=coalesce(p_settings->>'website',website),
    notice=coalesce(p_settings->>'notice',notice),
    thank_you=coalesce(p_settings->>'thank_you',thank_you),updated_at=now()
  where id=1;
end $$;

grant execute on function public.admin_create_user_account(uuid,text,text) to anon,authenticated;
grant execute on function public.user_login(text,text) to anon,authenticated;
grant execute on function public.get_quote_settings() to anon,authenticated;
grant execute on function public.admin_update_quote_settings(uuid,jsonb) to anon,authenticated;
