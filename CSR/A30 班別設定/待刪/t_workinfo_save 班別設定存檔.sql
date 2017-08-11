drop procedure if exists p_tworkinfo_save;

delimiter $$

create procedure p_tworkinfo_save
( 
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid varchar(36),
in_rwid int(10) unsigned ,
in_type varchar(36) ,
in_OnNext_Z04 tinyint(4) ,
in_OnDutyHHMM time ,
in_OffNext_Z04 tinyint(4) ,
in_OffDutyHHMM time ,
in_DelayBuffer int(11) ,
in_OverNext_Z04 tinyint(4) ,
in_OverSTHHMM time ,
in_OverBeforMin int(11) ,
in_OverAfterMin int(11) ,
in_OverHolidayMin int(11) ,
in_RangeSt int(11) ,
in_RangeEnd int(11) ,
in_WorkMinutes int(11) ,
out outMsg text,
out outRwid int,
out outError int
)
begin

declare err_code int default '0';
set @in_OUguid=ifnull(in_OUguid,'');
set @in_ltUser=ifnull(in_ltUser,'');
set @in_ltPid=ifnull(in_ltPid,'');
set @in_rwid  = ifnull(in_rwid,'0');
set @in_type  = ifnull(in_type,'');
set @in_OnNext_Z04  = ifnull(in_OnNext_Z04,'0');
set @in_OnDutyHHMM  = ifnull(in_OnDutyHHMM,'00:00:00'  );
set @in_OffNext_Z04  = ifnull(in_OffNext_Z04,'0');
set @in_OffDutyHHMM  = ifnull(in_OffDutyHHMM,'00:00:00'  );
set @in_DelayBuffer  = ifnull(in_DelayBuffer,'0');
set @in_OverNext_Z04  = ifnull(in_OverNext_Z04,'0');
set @in_OverSTHHMM  = ifnull(in_OverSTHHMM,'00:00:00'  );
set @in_OverBeforMin  = ifnull(in_OverBeforMin,'0');
set @in_OverAfterMin  = ifnull(in_OverAfterMin,'0');
set @in_OverHolidayMin  = ifnull(in_OverHolidayMin,'0');
set @in_RangeSt  = ifnull(in_RangeSt,'0');
set @in_RangeEnd  = ifnull(in_RangeEnd,'0');
set @in_WorkMinutes  = ifnull(in_WorkMinutes,'0');

SELECT CODEGUID into @in_WorkGuid FROM TCATCODE WHERE syscode='A01' and OUGUID=@in_OUguid 
  and (CODEID=@in_type or codeguid=@in_type);

insert into t_log (note) values
(concat(
@in_OUguid ,@in_LtUser ,@in_ltPid ,@in_rwid,@in_WorkGuid,@in_OnNext_Z04,@in_OnDutyHHMM,@in_OffNext_Z04,@in_OffDutyHHMM,@in_DelayBuffer,@in_OverNext_Z04,@in_OverSTHHMM,@in_OverBeforMin,@in_OverAfterMin,@in_OverHolidayMin,@in_RangeSt,@in_RangeEnd,@in_WorkMinutes 
));


if err_code='0' And @in_Rwid=0 Then # 新增
   insert into tworkinfo
   (
   LtUser ,ltPid ,WorkGuid,OnNext_Z04,OnDutyHHMM,OffNext_Z04,OffDutyHHMM,DelayBuffer,OverNext_Z04,OverSTHHMM,OverBeforMin,OverAfterMin,OverHolidayMin,RangeSt,RangeEnd,WorkMinutes)
   values 
   (@in_LtUser ,@in_ltPid ,@in_WorkGuid,@in_OnNext_Z04,@in_OnDutyHHMM,@in_OffNext_Z04,@in_OffDutyHHMM,@in_DelayBuffer,@in_OverNext_Z04,@in_OverSTHHMM,@in_OverBeforMin,@in_OverAfterMin,@in_OverHolidayMin,@in_RangeSt,@in_RangeEnd,@in_WorkMinutes 
   );
   set outMsg="新增完成";
   insert into t_log (note) values ("新增");
end if;

if err_code='0' And @in_Rwid>0 Then #修改
   update tworkinfo set  
   ltUser=@in_ltUser,
   ltpid=@in_ltpid, 
   OnNext_Z04=@in_OnNext_Z04,
   OnDutyHHMM=@in_OnDutyHHMM,
   OffNext_Z04=@in_OffNext_Z04,
   OffDutyHHMM=@in_OffDutyHHMM,
   DelayBuffer=@in_DelayBuffer,
   OverNext_Z04=@in_OverNext_Z04,
   OverSTHHMM=@in_OverSTHHMM,
   OverBeforMin=@in_OverBeforMin,
   OverAfterMin=@in_OverAfterMin,
   OverHolidayMin=@in_OverHolidayMin,
   RangeSt=@in_RangeSt,
   RangeEnd=@in_RangeEnd,
   WorkMinutes=@in_WorkMinutes  
   Where rwid=@in_Rwid;
 
   insert into t_log (note) values ("修改");
end if;


end 
