select count(*),a.rwid
from toffdoc a
inner join tofftype b on a.offtypeguid=b.offtypeguid and b.Can_Duplicate=0
where empguid='C153AE60-B2A2-4300-BB33-48374A98E79F' 
and offDoc_end   > '2014-05-12 00:00:00' /*請假起*/
and offDoc_start < '2014-05-13 10:10:00' /*請假迄*/
and a.rwid != 16419 /*請假單rwid*/;
 