-- WEB BUILD PC v2.0.5 - KIỂM TRA SAU NÂNG CẤP
select version,applied_at,note from public.app_schema_version where version='2.0.5';

select p.proname as rpc_name, pg_get_function_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in(
  'employee_save_quote','employee_list_quotes','employee_update_quote',
  'employee_delete_quote','admin_list_quote_history','user_login','admin_login'
)
order by p.proname;

select case when to_regclass('public.quote_history') is not null then 'OK' else 'MISSING' end as quote_history_table;

select count(*) as saved_quotes from public.quote_history;
