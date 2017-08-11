drop procedure if exists p_SysSet;
# 設定/還原 mysql 所以的初使值
delimiter $$
create procedure p_SysSet(
in_A int
)
begin
 /*
 call p_SysSet(0); 還原
 call p_SysSet(1); 設定
  
 */

if in_A in ('0','1') Then # A01 參數正確
  if in_A = 1 Then # B01 改變設定前，先儲存
 
   set @bak_sql_safe_updates = (select @@sql_safe_updates);
   set @bak_group_concat_max_len =(select @@group_concat_max_len );
   set @bak_max_heap_table_size=(select @@max_heap_table_size);

   set sql_safe_updates = 0;
   set group_concat_max_len=4294967295; # 32 bit 極限
  # set group_concat_max_len=18446744073709547520 # 64 bit 極限
   set max_heap_table_size=1024*(1024*1024); # engine=memory mb大小
 
  else # 0 還原
   if @bak_sql_safe_updates in (0,1) then
     set sql_safe_updates=@bak_sql_safe_updates;
     set group_concat_max_len =@bak_group_concat_max_len;
     set max_heap_table_size=@bak_max_heap_table_size;
   end if;
end if; # B01
end if; # A01


end