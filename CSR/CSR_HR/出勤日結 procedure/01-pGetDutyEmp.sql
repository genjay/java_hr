delimiter $$
#產生varDutyDate當日，在職員工資料到 tmpdutyemp
create procedure Get_Emp (varOUguid varchar(36),varDutyDate int)
begin
declare yestoday int ;
declare nextday int;
set yestoday=(select (str_to_date(varDutyDate,'%Y%m%d')-interval 1 day)+0);
set nextday =(select (str_to_date(varDutyDate,'%Y%m%d')+interval 1 day)+0);

set sql_safe_updates=0;
set max_heap_table_size=1024*(1024*1024); # engine=memory MB大小

create temporary table if not exists tmpdutyemp engine=memory
select a.ouguid,a.empguid,a.depguid,a.cardno
from tperson a
where  
    varDutyDate>=a.arrivedate # 到職後才要出勤
and varDutyDate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end #離職前要出勤
and varDutyDate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End #留停前要出勤
and varOUguid=a.OUguid;

delete from tmpdutyemp where ouguid=varOUguid ;

insert into tmpdutyemp
(ouguid,empguid,depguid,cardno)
select a.ouguid,a.empguid,a.depguid,a.cardno
from tperson a
where  
    varDutyDate>=a.arrivedate # 到職後才要出勤
and varDutyDate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end #離職前要出勤
and varDutyDate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End #留停前要出勤
and varOUguid=a.OUguid;

end$$