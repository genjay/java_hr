drop procedure if exists p_tOffQuota_save;

delimiter $$

create procedure p_tOffQuota_save(
in_OUguid varchar(36),
in_LtUser varchar(36),
in_ltPid  varchar(36),
in_Rwids  varchar(36), # '' 代表該tOverdoc 所有單據 
in_note text ,
out outMsg text,
out outRwid int,
out outError int
)

begin
# 補休加班，要加入一筆tOffQuota 才能有補休
/* 
 call p_tOffQuota_Overdoc(
'microjet',
'ltUser',
'Pid',
'' ,  # Rwid 0或'' 該ou全部加班單，
'' ,  # Note
@a,@b,@c
);
 

*/
set @in_OUguid= ifnull(in_OUguid,'');
set @in_ltUser= ifnull(in_ltUser,'');
set @in_ltPid = ifnull(in_ltPid,'');  
set @in_note  = ifnull(in_note,''); 
set @in_Rwids = ifnull(in_Rwids,0);
 

   drop table if exists tmp01;
   create   table tmp01 As
   Select  
    OverDocguid QuotaDocGuid       
    ,Empguid    Empguid
    ,year(dutydate) Quota_year
    ,a.Offtypeguid  OffTypeGuid
    ,0  Quota_seq
    ,(OverMins_Before+Overmins_After+OverMins_holiday)*OvertoOff_rate Quota_Offmins
    ,OverEnd Quota_valid_ST
    , (case
            when (`a`.`Valid_type_Z08` = 'd') then (`a`.`overEnd` + interval ifnull(`a`.`Valid_time`, 0) day)
            when (`a`.`Valid_type_Z08` = 'm') then (`a`.`overEnd` + interval ifnull(`a`.`Valid_time`, 0) month)
            when (`a`.`Valid_type_Z08` = 'y') then (`a`.`overEnd` + interval ifnull(`a`.`Valid_time`, 0) year)
        end) AS `Quota_Valid_End`
    from tOverDoc a
    Where 1=1
	and (a.rwid = @in_Rwids or @in_Rwids = 0 )
    and (a.offtypeguid is not null)
    and a.empguid in (select empguid from tperson where ouguid=@in_ouguid);

Delete from tOffquota # 刪除已不存在的加班單，補休單
where  isOverdoc=1 
and quotadocguid not in (select Overdocguid from tOverdoc)
and empguid in (select empguid from tperson where OUguid=@in_OUguid);

Delete from tOffquota # 刪除已存在的加班單，但是改成非補休
where  isOverdoc=1
and quotadocguid in (select overdocguid from tOverdoc Where offtypeguid is null)
and empguid in (select empguid from tperson where OUguid=@in_OUguid);

insert into tOffQuota
(QuotaDocGuid,Empguid,Quota_year,OffTypeGuid,Quota_seq,isOverdoc
,Quota_Offmins,Quota_valid_ST,Quota_Valid_End ) 
Select QuotaDocGuid,Empguid,Quota_year,OffTypeGuid,Quota_seq,1
,Quota_Offmins,Quota_valid_ST,Quota_Valid_End 
From tmp01 a
on duplicate key update 
 Quota_year=a.Quota_year
,OffTypeGuid=a.OffTypeGuid
,Quota_seq=a.Quota_seq
,isOverDoc=1
,Quota_Offmins=a.Quota_Offmins
,Quota_valid_ST=a.Quota_valid_ST
,Quota_Valid_End=a.Quota_Valid_End ;


end;