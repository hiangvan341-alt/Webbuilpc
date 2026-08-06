-- KIỂM TRA SAU KHI NÂNG CẤP v1.8.0
select version,applied_at,note from public.app_schema_version where version='1.8.0';

select p.proname as rpc_name,pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in (
 'employee_save_quote','employee_list_quotes','employee_update_quote','employee_delete_quote','admin_list_quote_history'
) order by p.proname;

select column_name,data_type from information_schema.columns
where table_schema='public' and table_name='quote_history'
order by ordinal_position;

select count(*) as total_quotes,count(distinct employee_username) as total_accounts_with_quotes
from public.quote_history;
