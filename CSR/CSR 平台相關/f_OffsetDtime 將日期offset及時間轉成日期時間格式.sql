drop function if exists f_OffsetDtime;

delimiter $$

create function f_OffsetDtime(
 inOffSet int # 日期的偏移 +- 的整數
,inDate date  # 基準日
,inTime text  # 時間 00:00:00
) returns datetime
begin

# 輸入，偏移、基準日、時間格式，產生標準時間格式

declare tmpStrC text;

set tmpStrC=date(inDate);
set tmpStrC=concat(tmpStrC,' ',inTime);

set tmpStrC=tmpStrC + interval inOffSet day;

return tmpStrC;

end