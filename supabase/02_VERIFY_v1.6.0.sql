-- WEB BUILD PC v1.6.0 - KIỂM TRA SAU NÂNG CẤP
-- Chạy file này sau 01_UPGRADE... Không sửa dữ liệu.

select 'schema_version' as test, version as result, applied_at::text as detail
from public.app_schema_version where version='1.6.0'
union all
select 'pgcrypto', case when to_regprocedure('extensions.crypt(text,text)') is not null then 'OK' else 'MISSING' end, 'extensions.crypt(text,text)'
union all
select 'user_login', case when to_regprocedure('public.user_login(text,text)') is not null then 'OK' else 'MISSING' end, 'public.user_login(text,text)'
union all
select 'create_user', case when to_regprocedure('public.admin_create_user_account(uuid,text,text)') is not null then 'OK' else 'MISSING' end, 'public.admin_create_user_account(uuid,text,text)'
union all
select 'list_users', case when to_regprocedure('public.admin_list_user_accounts(uuid)') is not null then 'OK' else 'MISSING' end, 'public.admin_list_user_accounts(uuid)'
union all
select 'reset_password', case when to_regprocedure('public.admin_reset_user_password(uuid,uuid,text)') is not null then 'OK' else 'MISSING' end, 'public.admin_reset_user_password(uuid,uuid,text)';

select username,is_active,
       case when password_hash ~ '^[$]2[aby][$][0-9]{2}[$]' then 'OK' else 'CẦN ADMIN CẤP LẠI MẬT KHẨU' end as password_status,
       created_at,last_login_at
from public.user_accounts
order by created_at desc;

select p.proname,pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in(
'admin_create_user_account','admin_list_user_accounts','admin_update_user_account',
'admin_reset_user_password','admin_delete_user_account','user_login')
order by p.proname,arguments;
