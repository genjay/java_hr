
# call pReport_d01('microjet','20140401','tmpD06');


drop procedure if exists pReport_d01;

delimiter $$

create procedure pReport_d01(
inOuguid varchar(36),
inDutydate date,
inTable_name varchar(36)
)

begin

DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN   
 # 發生sql error 時，drop tmp_ table 
 
 drop table if exists tmp_d01A;
 drop table if exists tmp_d01B;
 drop table if exists tmp_d01C_1;
 drop table if exists tmp_d01C;
 END; 

set @inOUguid=inOUguid;
set @inDutydate=inDutydate;
set @inTable_name=inTable_name;

/*
 出勤日報
 call pReport_d01('microjet','20140401','tmpD06');
*/

drop table if exists tmp_d01A;
create temporary table tmp_d01A as
select b.empid,a.dutydate,c.codeid workid,a.realon,realoff 
from tduty_a a
left join tperson b on a.empguid=b.empguid
left join tcatcode c on a.workguid=c.codeguid
where a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and dutydate = @inDutydate;

alter table tmp_d01a add index i01(empid,dutydate);

##########################################################

drop table if exists tmp_d01B;
create temporary table tmp_d01B as
select b.empid,a.dutydate,overA,overB,overC,overH,OverChange 
from tduty_c a
left join tperson b on a.empguid=b.empguid
where 
    a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.dutydate=@inDutydate;

alter table tmp_d01B add index i01(empid,dutydate);

#################################################################################
#
#  以下產生請假部份日報

drop table if exists tmp_d01C_1;
create temporary table tmp_d01C_1 as
select empid,a.dutydate,codeid offtype,dutyoffmins offmins
from tduty_b a
left join tperson b on a.empguid=b.empguid
left join tcatcode c on a.offtypeguid=c.codeguid
where
    a.empguid in (select empguid from tperson b where b.ouguid=@inOUguid)
and a.dutydate = @inDutydate
;

# 補上未使用的假別
select syscode into @syscode from tcatcode
where codeguid in (select offtypeguid from tduty_b a 
 where a.empguid in (select empguid from tperson b where b.ouguid=@inOUguid)
 and a.dutydate = @inDutydate) limit 1
;

insert into tmp_d01C_1 (empid,dutydate,offtype,offmins) 
select '' empid,0 dutydate,codeid,0 offmins
from tcatcode 
where syscode=@syscode and ifnull(codeid,'')!='';

alter table tmp_d01C_1 add index i01 (empid,dutydate);

select group_concat(codeid order by codeid) into @offtype_list
from tcatcode 
where syscode=@syscode and ifnull(codeid,'')!='' ;

call p03('empid,dutydate','offtype','offmins','tmp_d01C_1','tmp_d01c');

if inTable_name like 'tmp%' Then
set @sql= concat("drop table if exists " ,@inTable_name);
prepare s1 from @sql;
execute s1;

set @sql = concat("create temporary table ",@inTable_name," as ","
select a.empid,a.dutydate,a.workid,a.realon,a.realoff
,b.overA,b.overB,b.overC,b.overH,b.OverChange"
,",",@offtype_list
," from tmp_d01A a
left join tmp_d01B b on a.empid=b.empid and a.dutydate=b.dutydate
left join tmp_d01C c on a.empid=c.empid and a.dutydate=c.dutydate ;");
prepare s1 from @sql;
execute s1;

end if;

 drop table if exists tmp_d01A;
 drop table if exists tmp_d01B;
 drop table if exists tmp_d01C_1;
 drop table if exists tmp_d01C;

end