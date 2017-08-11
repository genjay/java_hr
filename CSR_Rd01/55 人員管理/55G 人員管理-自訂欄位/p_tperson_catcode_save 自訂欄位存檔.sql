drop procedure if exists p_tperson_catcode_save;

delimiter $$ 

create procedure p_tperson_catcode_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36) /*程式代號*/
,in_Emp_Rwid   int # 人員的rwid
,in_Data      text # 多筆格式資料 ('A01','B'),('A02','A')...
# (syscode,codeid)
,in_note      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;  
declare in_Emp_Guid varchar(36);

DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
    set outMsg='sql error';
    set err_code=1;
  end if;
END;  
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_catcode_save 執行中';

if err_code=0 then # 10 抓 Emp_Guid
 set isCnt=0;
 Select rwid,Emp_Guid into isCnt,in_Emp_Guid
 from tperson
 Where rwid=in_Emp_Rwid;
 if isCnt=0 then set err_code=1; set outMsg='Emp_Guid 有錯'; end if;
end if;

if err_code=0 then # 10 抓 codeguid
 set isCnt=0;
 drop table if exists tmp01;
 create temporary table tmp01 
 (syscode varchar(36),codeid varchar(36),codeguid varchar(36)) 
 engine=myisam ;
 
 set @sql=concat('Insert into tmp01 (syscode,codeid) values ',in_Data);
 prepare s1 from @sql;
 execute s1; 
 alter table tmp01 add index (syscode,codeid);

 Update tmp01 a,tcatcode b 
 Set a.codeguid=b.CodeGuid
 Where b.OUguid=in_OUguid
   and a.syscode=b.syscode and a.codeid=b.codeid;

end if; 

if err_code=0 then # 90 新增
  Insert into tperson_catcode
 (ltUser,ltPid,Emp_Guid,Syscode,Codeguid,note)
 select
 in_ltUser,in_ltPid,in_Emp_Guid,Syscode,Codeguid,in_note
 from tmp01 
 on duplicate key update
 Codeguid=tmp01.Codeguid;
 drop table if exists tmp01;
 set outMsg=concat('修改完成');
 set outRwid=last_insert_id();
 end if; # 90 
 
end; # begin