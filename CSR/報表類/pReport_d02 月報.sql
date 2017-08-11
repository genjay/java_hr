# call pReport_d02('microjet','201404','1','tmpD06');

drop procedure if exists pReport_d02;
# 出勤月報
delimiter $$

create procedure pReport_d02(
 inOuguid varchar(36)       # ouguid
,inPayYYYYMM varchar(7)     # 年月 '2014-04'
,inPayYYYYMM_seq varchar(3) # 每月多次算薪用
,inTable_name varchar(36)   # 產出報表 tmp_xx 開頭一定要 tmp
)

begin

DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN   
 # 發生sql error 時，drop tmp_ table 
 
 drop table if exists tmp_d02a;
 drop table if exists tmp_d02b;
 drop table if exists tmp_d02c;
 drop table if exists tmp_d02c_x;
 END; 

set @inOUguid=inOUguid;
set @inPayYYYYMM= replace(inPayYYYYMM,'-','');
set @inPayYYYYMM_seq= if(inPayYYYYMM_seq='','1',inPayYYYYMM_seq);
set @inTable_name=inTable_name;
 
drop table if exists tmp_d02a;
create temporary table tmp_d02a as
select b.empid,payYYYYMM,payYYYYMM_seq,a.Duty_Days
from tduty_sum_a a
left join tperson b on a.empguid=b.empguid 
where
 a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM=@inPayYYYYMM
and a.PayYYYYMM_seq=@inPayYYYYMM_seq;

drop table if exists tmp_d02b;
create temporary table tmp_d02b as
select b.empid,a.payYYYYMM,a.PayYYYYMM_seq,a.OverA,a.OverB,a.OverC,a.OverH
from tduty_sum_c a
left join tperson b on a.empguid=b.empguid 
where
 a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM=@inPayYYYYMM
and a.PayYYYYMM_seq=@inPayYYYYMM_seq;

/*==========================================
 請假月結計算開始
*/

drop table if exists tmp_d02c_x;
create temporary table tmp_d02c_x as
select b.empid,a.payYYYYMM,a.payYYYYMM_seq
,c.codeid offtype,a.offmins
from tduty_sum_b a
left join tperson b on a.empguid=b.empguid 
left join tcatcode c on a.offtypeguid=c.codeguid
where
 a.empguid in (select empguid from tperson where ouguid=@inOUguid)
and a.PayYYYYMM=@inPayYYYYMM
and a.PayYYYYMM_seq=@inPayYYYYMM_seq;

 
# 補上未使用的假別
select syscode into @syscode from tcatcode
where codeguid in (select offtypeguid from tduty_sum_b a 
 where a.empguid in (select empguid from tperson b where b.ouguid=@inOUguid)
 and a.payYYYYMM = @inPayYYYYMM and a.payYYYYMM_seq=@inPayYYYYMM_seq) limit 1
;

insert into tmp_d02c_x
(empid,payYYYYMM,payYYYYMM_seq,offtype)
select '' empid,0 payYYYYMM,'1' payYYYYMM_seq,codeid 
from tcatcode 
where syscode=@syscode and ifnull(codeid,'')!='';

select group_concat(codeid order by codeid) into @offtype_list
from tcatcode 
where syscode=@syscode and ifnull(codeid,'')!='' ;

call p03('empid','offtype','offmins/60','tmp_d02c_x','tmp_d02c');

/*==========================================
 請假月結計算結束
*/

if inTable_name like 'tmp%' Then 
set @sql_output = concat("drop table if exists ",inTable_name,";"); 
prepare s1 from @sql_output;
execute s1;

set  @sql_output = concat("create temporary table ",inTable_name
 ," as select a.empid,a.payYYYYMM,a.PayYYYYMM_seq
  ,b.OverA,b.OverB,b.OverC,b.OverH "
,",",@offtype_list
," from tmp_d02a a
left join tmp_d02b b on a.empid=b.empid 
left join tmp_d02c c on a.empid=c.empid ;");

prepare s1 from @sql_output;
execute s1;


end if;

end