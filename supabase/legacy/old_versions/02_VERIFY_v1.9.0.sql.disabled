select version,applied_at,note from public.app_schema_version where version='1.9.0';
select table_name from information_schema.tables where table_schema='public' and table_name in ('sample_configs','order_requests') order by table_name;
select p.proname,pg_get_function_arguments(p.oid) arguments from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('public_list_sample_configs','admin_list_sample_configs','admin_save_sample_config','admin_delete_sample_config','create_order_request','admin_list_order_requests','admin_update_order_request_status') order by p.proname;
select status,count(*) from public.order_requests group by status order by status;
