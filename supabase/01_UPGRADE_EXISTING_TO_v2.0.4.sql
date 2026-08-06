-- WEB BUILD PC v2.0.4 - NÂNG CẤP DATABASE HIỆN CÓ
-- Chạy duy nhất file này trên database đang dùng.
-- Không xóa sản phẩm, user, báo giá, đơn hàng hoặc tài khoản Admin.

begin;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

alter table public.admin_accounts add column if not exists role text not null default 'sub_admin';
update public.admin_accounts
set role=case when lower(trim(username))='admin' then 'super_admin'
              when role not in ('super_admin','sub_admin') then 'sub_admin'
              else role end;
alter table public.admin_accounts drop constraint if exists admin_accounts_role_check;
alter table public.admin_accounts add constraint admin_accounts_role_check check(role in('super_admin','sub_admin'));

create or replace function public.is_valid_admin(p_token uuid)
returns boolean language sql security definer set search_path=public
as $$select exists(select 1 from public.admin_sessions s join public.admin_accounts a on a.id=s.admin_id where s.token=p_token and s.expires_at>now() and a.is_active)$$;

create or replace function public.is_super_admin(p_token uuid)
returns boolean language sql security definer set search_path=public
as $$select exists(select 1 from public.admin_sessions s join public.admin_accounts a on a.id=s.admin_id where s.token=p_token and s.expires_at>now() and a.is_active and a.role='super_admin')$$;

drop function if exists public.admin_login(text,text);
create function public.admin_login(p_username text,p_password text)
returns table(token uuid,username text,role text)
language plpgsql security definer set search_path=public,extensions
as $$declare v_admin public.admin_accounts%rowtype;v_token uuid;begin
 select a.* into v_admin from public.admin_accounts a where lower(trim(a.username))=lower(trim(coalesce(p_username,''))) and a.is_active and a.password_hash=extensions.crypt(coalesce(p_password,''),a.password_hash) limit 1;
 if v_admin.id is null then raise exception 'Sai tài khoản hoặc mật khẩu';end if;
 delete from public.admin_sessions where expires_at<now();
 insert into public.admin_sessions(admin_id) values(v_admin.id) returning admin_sessions.token into v_token;
 return query select v_token,v_admin.username,v_admin.role;
end$$;

drop function if exists public.admin_create_account(uuid,text,text);
create function public.admin_create_account(p_token uuid,p_username text,p_password text)
returns void language plpgsql security definer set search_path=public,extensions
as $$declare v_username text:=lower(trim(coalesce(p_username,'')));begin
 if not public.is_super_admin(p_token) then raise exception 'Chỉ Admin chính mới được tạo tài khoản Admin phụ';end if;
 if v_username !~ '^[a-z0-9_.-]{3,40}$' then raise exception 'Tên tài khoản không hợp lệ';end if;
 if length(coalesce(p_password,''))<6 then raise exception 'Mật khẩu phải có ít nhất 6 ký tự';end if;
 insert into public.admin_accounts(username,password_hash,role,is_active) values(v_username,extensions.crypt(p_password,extensions.gen_salt('bf',12)),'sub_admin',true);
exception when unique_violation then raise exception 'Tên tài khoản Admin đã tồn tại';end$$;

create table if not exists public.app_schema_version(version text primary key,applied_at timestamptz not null default now(),note text not null default '');
insert into public.app_schema_version(version,note) values('2.0.4','Admin phụ có toàn bộ quyền quản trị trừ quyền tạo tài khoản Admin') on conflict(version) do update set applied_at=now(),note=excluded.note;

revoke all on function public.admin_login(text,text) from public;
revoke all on function public.admin_create_account(uuid,text,text) from public;
revoke all on function public.is_super_admin(uuid) from public;
grant execute on function public.admin_login(text,text) to anon,authenticated;
grant execute on function public.admin_create_account(uuid,text,text) to anon,authenticated;
grant execute on function public.is_super_admin(uuid) to anon,authenticated;
notify pgrst,'reload schema';
commit;
