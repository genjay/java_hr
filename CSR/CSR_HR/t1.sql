create temporary table t9 
select a.ouguid,a.empguid,a.dutydate,a.holiday,b.cuttime
#,a.workguid,a.stdon,a.overon,restst,restend
,a.realon,a.realoff
#上班前08:20，使用之休息時間
,Sum(Case When b.restST< a.stdOn #休息ST早於8:20(標準上班)不等於
 and a.realON between b.restST and b.restEND Then minute(timediff(a.realon,b.restEnd)) 
 When b.restST< a.stdOn and a.realon<=b.restST Then minute(timediff(b.restEnd,b.restST))
 When b.restST< a.stdOn and a.realOn> b.restEnd Then 0 
else 0  end) restA
,Sum(Case 
 When ((b.restSt >= a.stdON and b.restST<a.stdOff) or b.restEND >  a.stdON and b.restEND<=a.stdOff)
  and a.realon<b.restST and a.realoff>b.restST Then minute(timediff(b.restEnd,b.restST))
 When (b.restSt between a.stdON and a.stdOff or b.restEND between a.stdON and a.stdOff)
  and a.realon between b.restST and b.restEnd Then minute(timediff(b.restEnd,a.realOn))
 When (b.restSt between a.stdON and a.stdOff or b.restEND between a.stdON and a.stdOff)
  and a.realOn>b.restEnd Then 0 Else 0 End) restB
from t1 a
inner join tmprest b on a.ouguid=b.ouguid 
and a.workguid=b.workguid  
and a.holiday=b.holiday
and (a.realon between b.restST and b.restEND or
	a.realoff between b.restST and b.restEND or
    b.restST between a.realon and a.realoff or
    b.restEND between a.realOn and a.realOff)
group by a.ouguid,a.empguid,a.dutydate,a.holiday,b.cuttime
#,a.workguid,a.stdon,a.overon,restst,restend
,a.realon,a.realoff;

create index i01 on tmprest (ouguid,workguid,holiday) using btree;

alter table tmprest drop index i01;
drop table t9;

select a.* from t9 a
left join tperson b on a.empguid=b.empguid
where b.empid='a00514' #workrestmm!=workrestbb
order by a.empguid ;

select * from t1;