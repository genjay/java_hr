drop procedure if exists p_runSQL;

delimiter $$

create procedure p_runSQL(
 in_Text text 
)
begin
/*
取代在procedure 使用prepare ，execute
因為若同時使用 cursor for select...
會有只執行一筆的問題
*/ 
declare bakText text;

set bakText = @in_p_runSQL_Text;  # @in_Text 為全域變數
 
set @in_p_runSQL_Text=in_Text;
prepare s1 from @in_p_runSQL_Text;   #無法使用declare 變數，只能用@全域變數
execute s1; 
# insert into t_log (note) values (in_text);

set  @in_p_runSQL_Text=bakText;  # 還原 in_Text 全域變數值
end 