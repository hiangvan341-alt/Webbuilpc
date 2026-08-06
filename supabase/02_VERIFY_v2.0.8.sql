-- Web Build PC v2.0.8 - kiểm tra trong một bảng duy nhất
select * from (
  select 1 stt,'Schema version 2.0.8' hang_muc,
    case when exists(select 1 from public.app_schema_version where version='2.0.8') then 'OK' else 'MISSING' end ket_qua
  union all select 2,'Cột quote_history.quote_name',case when exists(
    select 1 from information_schema.columns where table_schema='public' and table_name='quote_history' and column_name='quote_name'
  ) then 'OK' else 'MISSING' end
  union all select 3,'RPC employee_save_quote',case when to_regprocedure('public.employee_save_quote(uuid,text,text,text,text,jsonb,numeric,jsonb)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
  union all select 4,'RPC employee_list_quotes',case when to_regprocedure('public.employee_list_quotes(uuid,text)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
  union all select 5,'RPC employee_update_quote',case when to_regprocedure('public.employee_update_quote(uuid,uuid,text,text,text,text,jsonb,numeric)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
  union all select 6,'RPC employee_delete_quote',case when to_regprocedure('public.employee_delete_quote(uuid,uuid)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
  union all select 7,'RPC admin_list_quote_history',case when to_regprocedure('public.admin_list_quote_history(uuid,text)') is not null then 'OK' else 'MISSING / WRONG SIGNATURE' end
  union all select 8,'Báo giá thiếu tên',case when not exists(select 1 from public.quote_history where trim(coalesce(quote_name,''))='') then 'OK' else 'CẦN CHẠY LẠI UPGRADE' end
) x order by stt;
