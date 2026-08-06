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
