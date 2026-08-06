-- KIỂM TRA SAU NÂNG CẤP v1.7.0
select 'schema_version' as test,coalesce((select version from public.app_schema_version order by applied_at desc limit 1),'MISSING') as result;
select 'quote_history_table' as test,case when to_regclass('public.quote_history') is not null then 'OK' else 'MISSING' end as result;
select p.proname,pg_get_function_arguments(p.oid) arguments,pg_get_function_result(p.oid) result
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in('user_login','employee_save_quote','employee_list_quotes','admin_list_quote_history') order by p.proname;
select count(*) as total_quotes,count(distinct employee_id) as employees_with_quotes,count(distinct lower(customer_name)) as customers from public.quote_history;
