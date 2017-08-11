drop procedure if exists p_tperson_ice_save;

delimiter $$ 

create procedure p_tperson_ice_save
(
 in_OUguid                    varchar(36)
,in_LtUser                    varchar(36)
,in_ltPid                     varchar(36)
,in_rwid                      int(10) unsigned
,in_Emp_ID                    varchar(36)
,in_ICE_Name                  varchar(45)
,in_ICE_relationship          varchar(45)
,in_ICE_Tel1                  varchar(45)
,in_ICE_Tel2                  varchar(45)
,in_note                      text
,out outMsg   text # 回傳訊息
,out outRwid  int  # 回傳單據號，新增單號、錯誤單號
,out err_code int  # err_code
)  

begin
declare isCnt int;   
declare in_Emp_Guid varchar(36);

/*
DECLARE EXIT HANDLER FOR SQLEXCEPTION #, SQLWARNING
BEGIN
    ROLLBACK;
  if 1=1 then # drop temp table
    drop table if exists tmp01;
  end if;
END;  
*/
 
set err_code=0; set outRwid=0; set outMsg='p_tperson_ice_save 執行中';

if err_code=0 then
 set isCnt=0;
 Select rwid,Emp_Guid into isCnt,in_Emp_Guid 
 from tperson Where OUguid=in_OUguid and Emp_ID=in_Emp_ID limit 1;
 if isCnt=0 then set err_code=1; set outMsg='人員錯誤'; end if;
end if;

if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tperson_ice 
  Where rwid=in_Rwid And Emp_Guid=in_Emp_Guid And ICE_Name=in_ICE_Name And ICE_relationship=in_ICE_relationship And ICE_Tel1=in_ICE_Tel1 And ICE_Tel2=in_ICE_Tel2 And note=in_note
  limit 1;
 if isCnt>0 then set err_code=1; set outMsg='資料無修改'; end if;
 end if;
 
 if err_code=0 then # 判斷是否有無修改
  set isCnt=0; 
  Select rwid into isCnt 
   From tperson_ice 
  Where rwid!=in_Rwid And Emp_Guid=in_Emp_Guid And ICE_Name=in_ICE_Name And ICE_relationship=in_ICE_relationship And ICE_Tel1=in_ICE_Tel1 And ICE_Tel2=in_ICE_Tel2 And note=in_note
  limit 1;
 if isCnt>0 then set err_code=1; set outMsg='已存在相同資料'; end if;
 end if;

if err_code=0 && in_Rwid=0 then # 90 新增
  Insert into tperson_ice
 (ltUser,ltPid,Emp_Guid,ICE_Name,ICE_relationship,ICE_Tel1,ICE_Tel2,note)
 values 
 (in_ltUser,in_ltPid,in_Emp_Guid,in_ICE_Name,in_ICE_relationship,in_ICE_Tel1,in_ICE_Tel2,in_note);
 set outMsg=concat('「',in_ICE_Name,'」','新增完成');
 set outRwid=last_insert_id();
 end if; # 90 
 
  if err_code=0 && in_Rwid>0 then # 90 修改 
 Update tperson_ice Set
  ltUser                        = in_ltUser
 ,ltpid                         = in_ltpid
 ,Emp_Guid                      = in_Emp_Guid
 ,ICE_Name                      = in_ICE_Name
 ,ICE_relationship              = in_ICE_relationship
 ,ICE_Tel1                      = in_ICE_Tel1
 ,ICE_Tel2                      = in_ICE_Tel2
 ,note                          = in_note
  Where rwid=in_Rwid;
 set outMsg=concat('「',in_ICE_Name,'」','修改成功');
 set outRwid=in_Rwid;
 end if; # 90 修改
 

end; # begin