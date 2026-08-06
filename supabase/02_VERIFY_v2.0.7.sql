select * from (
 select 1 stt,'Schema version 2.0.7' hang_muc,case when exists(select 1 from public.app_schema_version where version='2.0.7') then 'OK' else 'MISSING' end ket_qua
 union all select 2,'Bảng user_saved_configs',case when to_regclass('public.user_saved_configs') is not null then 'OK' else 'MISSING' end
 union all select 3,'RPC user_list_saved_configs',case when to_regprocedure('public.user_list_saved_configs(uuid)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 4,'RPC user_save_config',case when to_regprocedure('public.user_save_config(uuid,uuid,text,text,jsonb,numeric)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 5,'RPC user_delete_saved_config',case when to_regprocedure('public.user_delete_saved_config(uuid,uuid)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 6,'RPC admin_list_user_saved_configs',case when to_regprocedure('public.admin_list_user_saved_configs(uuid,text)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 7,'RPC admin_create_sample_from_user_config',case when to_regprocedure('public.admin_create_sample_from_user_config(uuid,uuid,text,text,boolean)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 8,'RPC admin_update_sample_config',case when to_regprocedure('public.admin_update_sample_config(uuid,uuid,text,text,boolean)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 9,'RPC admin_save_sample_config v2.0.7',case when to_regprocedure('public.admin_save_sample_config(uuid,text,text,jsonb,numeric,boolean)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 10,'RPC employee_delete_quote',case when to_regprocedure('public.employee_delete_quote(uuid,uuid)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 11,'RPC validate_admin_session',case when to_regprocedure('public.validate_admin_session(uuid)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
 union all select 12,'RPC validate_user_session',case when to_regprocedure('public.validate_user_session(uuid)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
) x order by stt;
