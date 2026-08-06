
-- =========================================================
-- MODULE 60: USER SAVED CONFIGS + SAMPLE CONFIG MANAGEMENT
-- Version 2.0.7
-- =========================================================

create table if not exists public.user_saved_configs (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.user_accounts(id) on delete cascade,
  name text not null,
  description text not null default '',
  items jsonb not null default '[]'::jsonb,
  total numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists user_saved_configs_user_idx on public.user_saved_configs(user_id, updated_at desc);
alter table public.user_saved_configs enable row level security;

-- Ensure sample visibility column exists.
alter table public.sample_configs add column if not exists is_active boolean not null default true;

-- Remove all old signatures before recreating the current contracts.
drop function if exists public.user_list_saved_configs(uuid);
drop function if exists public.user_save_config(uuid,uuid,text,text,jsonb,numeric);
drop function if exists public.user_delete_saved_config(uuid,uuid);
drop function if exists public.admin_list_user_saved_configs(uuid,text);
drop function if exists public.admin_create_sample_from_user_config(uuid,uuid,text,text,boolean);
drop function if exists public.admin_update_sample_config(uuid,uuid,text,text,boolean);
drop function if exists public.admin_save_sample_config(uuid,text,text,jsonb,numeric);
drop function if exists public.admin_save_sample_config(uuid,text,text,jsonb,numeric,boolean);

create function public.user_list_saved_configs(p_token uuid)
returns table(id uuid,name text,description text,total numeric,items jsonb,created_at timestamptz,updated_at timestamptz)
language plpgsql security definer
set search_path=public,extensions
as $$
declare v_user uuid;
begin
  select s.user_id into v_user from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id and u.is_active
  where s.token=p_token and s.expires_at>now() limit 1;
  if v_user is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  return query select c.id,c.name,c.description,c.total,c.items,c.created_at,c.updated_at
  from public.user_saved_configs c where c.user_id=v_user order by c.updated_at desc;
end $$;

create function public.user_save_config(p_token uuid,p_config_id uuid,p_name text,p_description text,p_items jsonb,p_total numeric)
returns table(id uuid)
language plpgsql security definer
set search_path=public,extensions
as $$
declare v_user uuid; v_id uuid;
begin
  select s.user_id into v_user from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id and u.is_active
  where s.token=p_token and s.expires_at>now() limit 1;
  if v_user is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  if length(trim(coalesce(p_name,'')))<1 then raise exception 'Tên cấu hình không được để trống'; end if;
  if jsonb_array_length(coalesce(p_items,'[]'::jsonb))<1 then raise exception 'Cấu hình phải có ít nhất một sản phẩm'; end if;
  if p_config_id is null then
    insert into public.user_saved_configs(user_id,name,description,items,total)
    values(v_user,trim(p_name),trim(coalesce(p_description,'')),coalesce(p_items,'[]'::jsonb),greatest(coalesce(p_total,0),0)) returning user_saved_configs.id into v_id;
  else
    update public.user_saved_configs set name=trim(p_name),description=trim(coalesce(p_description,'')),items=coalesce(p_items,'[]'::jsonb),total=greatest(coalesce(p_total,0),0),updated_at=now()
    where user_saved_configs.id=p_config_id and user_id=v_user returning user_saved_configs.id into v_id;
    if v_id is null then raise exception 'Không tìm thấy cấu hình hoặc bạn không có quyền sửa'; end if;
  end if;
  return query select v_id;
end $$;

create function public.user_delete_saved_config(p_token uuid,p_config_id uuid)
returns void language plpgsql security definer set search_path=public,extensions
as $$
declare v_user uuid;
begin
  select s.user_id into v_user from public.user_sessions s
  join public.user_accounts u on u.id=s.user_id and u.is_active
  where s.token=p_token and s.expires_at>now() limit 1;
  if v_user is null then raise exception 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn'; end if;
  delete from public.user_saved_configs where id=p_config_id and user_id=v_user;
  if not found then raise exception 'Không tìm thấy cấu hình hoặc bạn không có quyền xóa'; end if;
end $$;

create function public.admin_list_user_saved_configs(p_token uuid,p_search text default null)
returns table(id uuid,owner_username text,name text,description text,total numeric,items jsonb,created_at timestamptz,updated_at timestamptz)
language plpgsql security definer set search_path=public,extensions
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  return query select c.id,u.username,c.name,c.description,c.total,c.items,c.created_at,c.updated_at
  from public.user_saved_configs c join public.user_accounts u on u.id=c.user_id
  where coalesce(trim(p_search),'')='' or u.username ilike '%'||trim(p_search)||'%' or c.name ilike '%'||trim(p_search)||'%'
  order by c.updated_at desc;
end $$;

create function public.admin_save_sample_config(p_token uuid,p_name text,p_description text,p_items jsonb,p_total numeric,p_is_active boolean default true)
returns table(id uuid)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_admin uuid; v_id uuid;
begin
  select s.admin_id into v_admin from public.admin_sessions s join public.admin_accounts a on a.id=s.admin_id and a.is_active where s.token=p_token and s.expires_at>now() limit 1;
  if v_admin is null then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  if length(trim(coalesce(p_name,'')))<1 then raise exception 'Tên cấu hình không được để trống'; end if;
  insert into public.sample_configs(name,description,items,total,created_by,is_active)
  values(trim(p_name),trim(coalesce(p_description,'')),coalesce(p_items,'[]'::jsonb),greatest(coalesce(p_total,0),0),v_admin,coalesce(p_is_active,true)) returning sample_configs.id into v_id;
  return query select v_id;
end $$;

create function public.admin_update_sample_config(p_token uuid,p_config_id uuid,p_name text,p_description text,p_is_active boolean)
returns void language plpgsql security definer set search_path=public,extensions
as $$
begin
  if not public.is_valid_admin(p_token) then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  update public.sample_configs set name=trim(p_name),description=trim(coalesce(p_description,'')),is_active=coalesce(p_is_active,false) where id=p_config_id;
  if not found then raise exception 'Không tìm thấy cấu hình mẫu'; end if;
end $$;

create function public.admin_create_sample_from_user_config(p_token uuid,p_user_config_id uuid,p_name text,p_description text,p_is_active boolean default true)
returns table(id uuid)
language plpgsql security definer set search_path=public,extensions
as $$
declare v_admin uuid; v_source public.user_saved_configs%rowtype; v_id uuid;
begin
  select s.admin_id into v_admin from public.admin_sessions s join public.admin_accounts a on a.id=s.admin_id and a.is_active where s.token=p_token and s.expires_at>now() limit 1;
  if v_admin is null then raise exception 'Phiên quản trị không hợp lệ hoặc đã hết hạn'; end if;
  select * into v_source from public.user_saved_configs where user_saved_configs.id=p_user_config_id;
  if v_source.id is null then raise exception 'Không tìm thấy cấu hình đã lưu'; end if;
  insert into public.sample_configs(name,description,items,total,created_by,is_active)
  values(coalesce(nullif(trim(p_name),''),v_source.name),coalesce(nullif(trim(p_description),''),v_source.description),v_source.items,v_source.total,v_admin,coalesce(p_is_active,true)) returning sample_configs.id into v_id;
  return query select v_id;
end $$;

revoke all on table public.user_saved_configs from anon,authenticated;
revoke all on function public.user_list_saved_configs(uuid) from public;
revoke all on function public.user_save_config(uuid,uuid,text,text,jsonb,numeric) from public;
revoke all on function public.user_delete_saved_config(uuid,uuid) from public;
revoke all on function public.admin_list_user_saved_configs(uuid,text) from public;
revoke all on function public.admin_create_sample_from_user_config(uuid,uuid,text,text,boolean) from public;
revoke all on function public.admin_update_sample_config(uuid,uuid,text,text,boolean) from public;
revoke all on function public.admin_save_sample_config(uuid,text,text,jsonb,numeric,boolean) from public;

grant execute on function public.user_list_saved_configs(uuid) to anon,authenticated;
grant execute on function public.user_save_config(uuid,uuid,text,text,jsonb,numeric) to anon,authenticated;
grant execute on function public.user_delete_saved_config(uuid,uuid) to anon,authenticated;
grant execute on function public.admin_list_user_saved_configs(uuid,text) to anon,authenticated;
grant execute on function public.admin_create_sample_from_user_config(uuid,uuid,text,text,boolean) to anon,authenticated;
grant execute on function public.admin_update_sample_config(uuid,uuid,text,text,boolean) to anon,authenticated;
grant execute on function public.admin_save_sample_config(uuid,text,text,jsonb,numeric,boolean) to anon,authenticated;

insert into public.app_schema_version(version,applied_at) values('2.0.7',now()) on conflict(version) do update set applied_at=excluded.applied_at;
notify pgrst,'reload schema';
