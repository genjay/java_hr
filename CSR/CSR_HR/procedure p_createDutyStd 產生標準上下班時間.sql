delimiter $$

create procedure p_createDutyStd 
(in var_ouguid varchar(36),in var_dutydate int)
begin 

set sql_safe_updates=0;

delete from tmpdutystd where ouguid=var_ouguid and dutydate=var_dutydate;

insert into tmpdutystd
(ouguid,empguid,cardno,dutydate,workguid,holiday,stdON
,stdOff,OverOn,buffermm,RangeSt,RangeEnd)
select a.ouguid,a.empguid,a.cardno,b.dutydate,b.workguid,b.holiday,b.stdON
,b.stdOff,b.OverOn,b.buffermm,b.RangeSt,b.RangeEnd
from tperson a
left join vdutystd b on a.empguid=b.empguid
where b.ouguid=var_ouguid and dutydate=var_dutydate;

end $$
delimiter ;
 
 


