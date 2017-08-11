drop procedure if exists p_tCatCode_del; # 分類碼刪除

delimiter $$

create procedure p_tCatCode_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/ 
,in_Rwid int  /*要修改的單據rwid*/
,out outMessage text /*回傳訊息，直接給user看的*/
,out outDupRWID int  /*重疊的請假單*/
,out outErr_code int /*成功失敗代碼*/
)

begin
/* 
call p_tCatCode_del
(
 'microjet'
,'ltuser'
,'ltpid'
,33   # tcatcode.rwid
,@a
,@b
,@c
);

*/
DECLARE err_code int default '0';  
declare iFinish int;
declare str_A text;
declare str_B text;
 
declare cur_1 cursor for select 
concat(
"select rwid into @isCnt from "
,a.table_name," "
," Where "
,a.column_name
,"= @in_codeGuid limit 1;") ,concat(a.table_name,'.',a.column_name)
from information_schema.columns a
left join information_schema.tables b on a.table_schema=b.table_schema and a.table_name=b.table_name
Where  1=1 
and a.table_schema=schema()
and b.table_type='BASE TABLE' 
and a.column_name like '%guid'
;
declare continue handler for not found set iFinish=1;
 
set @in_OUguid=in_OUguid;
set @in_ltUser =in_ltUser;
set @in_ltpid = in_ltpid;  
set @in_Rwid =in_Rwid;
set @useTables='';


select count(*),codeGuid into @isCnt,@in_codeGuid from tcatcode where codeid!='' and ouguid=@in_ouguid and rwid=@in_rwid;
if @isCnt=0 Then set err_code=1; set outMessage="無此筆資料"; end if;

if @err_code = 0 Then # A01 判斷是否被使用過
open cur_1;
repeat
fetch cur_1 into str_A,str_B;
   if @bak_a != str_A Then # 等於時，代表最後一筆
   # set  @str_A=concat("insert into t_log (note) values ('",str_A,"');");
   set @str_A=concat(str_A); 
   set @str_B=str_B;

   set @isCnt =0;
   call p_runsql( @str_A );

   if @isCnt > 0 Then 
      set iFinish=1;
      set outMessage= concat("無法刪除，已被",ifnull(@str_B,'')," 此欄位使用");
      set outDupRWID=concat(@isCnt); 
      set err_code=1;
    end if;
       
      set @bak_a=str_A; 
   end if;
until iFinish=1 end repeat;
close cur_1; 

end if; # A01

 if err_code=0 Then # B01
    delete from tcatcode where codeid!='' And rwid=@in_rwid; # codeid='' 代表是syscode，不能刪
 end if; # B01

  set outErr_code= err_code;
end