drop procedure if exists p_tSchEmp_save; # 個人出勤曆存檔

delimiter $$

create procedure p_tSchEmp_save
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) 
,in_EmpID varchar(36) 
,in_DutyDate date  
,in_Holiday int  
,in_Type varchar(36)  
,out outMsg text  
,out outRwid int   
,out outError int  
)

begin
/*
call p_tSchEmp_save
(
'microjet'
,'ltUser'
,'ltPid'
,'a00024'
,'20140603'
,'0'
,'O'
,@a
,@b
,@c
);

select @a,@b,@c,@in_Empguid,@in_typeGuid;
*/


declare err_code int default 0;

set @in_OUguid=ifnull(in_OUguid,'');
set @in_ltUser=ifnull(in_ltUser,'');
set @in_ltPid=ifnull(in_ltPid,''); 
set @in_EmpID  = ifnull(in_EmpID,'');
set @in_dutydate  = ifnull(in_dutydate,'2000-01-01');
set @in_Holiday  = ifnull(in_Holiday,'0');
set @in_Type  = ifnull(in_Type,'');

set @in_EmpGuid='';
set @in_TypeGuid='';
set @in_Rwid=0;
 
   if err_code=0 Then # A01 抓Empguid 
      set @in_EmpGuid='';
      Select empguid into @in_EmpGuid from tperson where OUguid=@in_OUguid 
       and (EmpID=@in_EmpID or EmpGuid=@in_EmpID 
        or empguid =(select empguid from tforgetdoc where rwid=@in_rwid)); 

   if err_code=0 And ifnull(@in_Rwid,0)=0 And ifnull(@in_EmpGuid,'')='' Then set err_code=1; set @outMsg="工號錯誤";end if; 

end if; # A01
 
   if err_code=0 Then # A02 判斷班別
      set @in_TypeGuid='';
	  Select codeguid into @in_TypeGuid from tcatcode Where syscode='A01' and OUguid=@in_OUguid and (codeID=@in_Type or codeGuid=@in_Type); 
      if err_code=0 And ifnull(@in_TypeGuid,'')='' Then set err_code=1; set @outMsg="班別錯誤"; end if;

   end if;

   if err_code=0 Then # A03 判斷是否與前後一日，上班時間重疊
      drop table if exists tmp01;
      create temporary table tmp01 as 
      select   empguid
       ,cast(@in_Dutydate as date) DutyDate
       ,cast(@in_typeGuid as char(36)) WorkGuid
       ,(str_to_date(concat(@in_Dutydate, `d`.`OnDutyHHMM`),
                '%Y-%m-%d%H:%i:%s') + interval `d`.`OnNext_Z04` day) AS `Std_on`,
        (str_to_date(concat(@in_Dutydate, `d`.`OffDutyHHMM`),
                '%Y-%m-%d%H:%i:%s') + interval `d`.`OffNext_Z04` day) AS `Std_off`
      from tperson a
      left join tworkinfo d on d.WorkGuid=@in_typeGuid
      where empguid=@in_Empguid ;
      alter table tmp01 add index i01 (empguid,dutydate);

	  set @isCnt=0;
      set @dutyList='';
        select count(*),group_concat(b.dutydate order by 1) into @isCnt,@dutyList
        from tmp01 a
        left join vdutystd_emp b on a.empguid=b.empguid 
         and a.dutydate != b.dutydate
         and b.dutydate between (a.dutydate- interval 1 day) And (a.dutydate+interval 1 day)  
        Where a.empguid=@in_Empguid
         and a.std_On < b.std_Off
         and a.std_Off > b.std_On	  ; 

	if @isCnt > 0 Then # 代表班別錯誤
       set err_code='1'; set @outMsg=concat(@in_dutydate,"班別錯誤，與其它日上班時日重疊：",@dutyList);   
    end if;
   
   end if;

   set outMsg=@outMsg;
   set outError=err_code;
end