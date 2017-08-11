#產生出勤日使用休息時間狀況
create temporary table t9 
select a.ouguid,a.empguid,a.dutydate
,b.cuttime
,Sum(Case 
 When b.restST<a.stdOn 
 Then minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
 Else 0 end) restA
,Sum(Case 
 When b.restEnd>=a.stdOn and b.restST<a.stdOff
 Then minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
 Else 0 end) restB
,Sum(Case 
When b.restEnd>a.stdOff
Then minute(timediff(
           IF( a.realon between b.restST and b.restEnd,a.realon,b.restST)
		  ,IF(a.realoff between b.restST and b.restEnd,a.realOff,restEnd)))
Else 0 end) restC
from t1 a
inner join tmprest b on a.ouguid=b.ouguid 
and a.workguid=b.workguid  
and a.holiday=b.holiday
and (a.realon between b.restST and b.restEND or
	a.realoff between b.restST and b.restEND or
    b.restST between a.realon and a.realoff or
    b.restEND between a.realOn and a.realOff)
#where a.empguid='C153AE60-B2A2-4300-BB33-48374A98E79F'
group by ouguid,empguid,dutydate,cuttime
;
