-- KIỂM TRA SAU NÂNG CẤP v2.0.6
-- Chỉ đọc dữ liệu, không sửa nghiệp vụ.

select 'schema_version' as check_name,
       coalesce((select version from public.app_schema_version where version='2.0.6'),'MISSING') as result;

with required_tables(name) as (values
 ('products'),('admin_accounts'),('admin_sessions'),('user_accounts'),('user_sessions'),
 ('quote_settings'),('quote_history'),('sample_configs'),('order_requests')
)
select 'table.'||r.name as check_name,
       case when to_regclass('public.'||r.name) is not null then 'OK' else 'MISSING' end as result
from required_tables r order by r.name;

with required_functions(name,args) as (values
 ('admin_login','text, text'),
 ('admin_logout','uuid'),
 ('validate_admin_session','uuid'),
 ('admin_create_account','uuid, text, text'),
 ('admin_import_products','uuid, jsonb'),
 ('admin_create_user_account','uuid, text, text'),
 ('admin_list_user_accounts','uuid'),
 ('admin_update_user_account','uuid, uuid, text, boolean'),
 ('admin_reset_user_password','uuid, uuid, text'),
 ('admin_delete_user_account','uuid, uuid'),
 ('user_login','text, text'),
 ('user_logout','uuid'),
 ('validate_user_session','uuid'),
 ('employee_save_quote','uuid, text, text, text, text, jsonb, numeric, jsonb'),
 ('employee_list_quotes','uuid, text'),
 ('employee_update_quote','uuid, uuid, text, text, text, text, jsonb, numeric'),
 ('employee_delete_quote','uuid, uuid'),
 ('admin_list_quote_history','uuid, text'),
 ('public_list_sample_configs',''),
 ('admin_list_sample_configs','uuid'),
 ('admin_save_sample_config','uuid, text, text, jsonb, numeric'),
 ('admin_delete_sample_config','uuid, uuid'),
 ('create_order_request','uuid, text, text, text, text, jsonb, numeric'),
 ('admin_list_order_requests','uuid, text'),
 ('admin_update_order_request_status','uuid, uuid, text'),
 ('get_quote_settings',''),
 ('admin_update_quote_settings','uuid, jsonb')
)
select 'rpc.'||r.name as check_name,
       case when exists(
         select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
         where n.nspname='public' and p.proname=r.name
           and pg_get_function_identity_arguments(p.oid)=r.args
       ) then 'OK' else 'MISSING / WRONG SIGNATURE' end as result
from required_functions r order by r.name;

select 'admin_account.'||username as check_name,
       case when is_active then role else 'DISABLED' end as result
from public.admin_accounts order by username;

select 'user.'||username as check_name,
       case when is_active and password_hash ~ '^[$]2[aby][$][0-9]{2}[$]' then 'OK'
            when not is_active then 'DISABLED'
            else 'RESET PASSWORD' end as result
from public.user_accounts order by username;

select * from public.validate_admin_session(null::uuid);
select * from public.validate_user_session(null::uuid);
