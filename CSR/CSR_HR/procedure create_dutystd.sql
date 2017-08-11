delimiter //
create procedure create_dutyStd 
(in inOUguid varchar(36),in indaySt int,in indayEnd int)
begin
drop table if exists t3;
set max_heap_table_size=512*8*1024*1024;#設定engine=memory 容量大小
 create table if not exists t3  engine=memory
 #explain 
select a.ouguid,a.empid,a.empname,a.cardno
,b.dutydate
,ifnull(c.holiday,b.holiday) holiday
,d.workid
from tperson a
left join tdepsch b on a.ouguid=b.ouguid and b.depguid=a.depguid 
left join tempsch c on a.ouguid=c.ouguid and c.empguid=a.empguid and b.dutydate=c.dutydate
left join tworkinfo d on a.ouguid=d.ouguid and d.workguid=ifnull(c.workguid,b.workguid)
where 
b.dutydate>=a.arrivedate 
and b.dutydate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end
and b.dutydate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End 
and b.dutydate between indaySt and indayEnd 
and a.ouguid=inOUguid
;
end //
delimiter ;

drop procedure create_dutyStd;

call create_dutystd('microjet',20130401,20130401);

drop table t3;

select * from t3;

delimiter //
create procedure ss1 (out param1 int)
begin
 select count(*) into param1 from tperson;
end //
delimiter ;

