-- KIỂM TRA SAU KHI NÂNG CẤP v2.0.4
select version,applied_at,note from public.app_schema_version where version='2.0.4';

select username,role,is_active,created_at
from public.admin_accounts
order by case when role='super_admin' then 0 else 1 end,created_at;

select p.proname,pg_get_function_result(p.oid) result,pg_get_function_arguments(p.oid) arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in('admin_login','admin_create_account','is_super_admin')
order by p.proname;

select case when exists(select 1 from public.admin_accounts where role='super_admin' and is_active)
 then 'OK: Có Admin chính' else 'LỖI: Không có Admin chính' end as super_admin_check;
