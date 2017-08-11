call p_createdutystd('microjet',20130401);

# 實際上下班，再算使用彈性，延後時間…
select 
a.ouguid,a.empguid,a.dutydate,a.holiday
,realon,realoff,a.stdon
,Case When realon between stdon and (stdon+interval c.buffermm minute)
 then minute(timediff(realon,a.stdon)) else 0 end  as usebuffer #使用彈性時間
,Case When realon < stdON 
 then minute(timediff(stdon,realon)) else 0 end beforMM#早到時間
,Case When realoff> overON then (timediff(realoff,overon)) else 0 end OverMM #延後可報加班時間
,Case When realon>stdon + interval buffermm minute then timediff(realon,stdon) else 0 end delayHM
,(select sum(
 Case When a.realon<=s.restst and a.realoff>=s.restEnd Then restmm end +
 Case When a.realoff between s.restST and s.restEnd Then minute(timediff(a.realoff,s.restST)) else 0 end
 ) from tmprest s
 where a.ouguid=s.ouguid and a.workguid=s.workguid and a.dutydate=s.dutydate
 and a.holiday=s.holiday)
from t1 a
left join tperson b on a.ouguid=b.ouguid and a.empguid=b.empguid
left join tworkinfo c on a.ouguid=c.ouguid and a.workguid=c.workguid
where b.empid in ('a01816','a00024') 
group by a.ouguid,a.empguid,a.dutydate,a.holiday
,realon,realoff,a.stdon;
 
# 產生使用休息時間資料
select c.empid,a.realon,a.realoff,restno,restst,restend
,Case When realon<=restst and realoff>=restend then restmm 
 When realon between restst and restend Then minute(timediff(realon,restEnd))
 When realoff between restst and restend Then minute(timediff(realoff,restst))
 else 0 end userest
from t1 a
left join tmprest b on a.ouguid=b.ouguid and a.workguid=b.workguid
 and a.dutydate=b.dutydate and a.holiday=b.holiday
left join tperson c on a.empguid=c.empguid
where c.empid in ('a01816','a00514' )
and (a.realon<=restst and a.realoff>=restSt) 
 