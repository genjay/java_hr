alter view vdutyStd As 
select a.ouguid,a.empguid,a.cardno
,b.dutydate
,d.workguid
,ifnull(c.holiday,b.holiday) holiday
,str_to_date(concat(b.dutydate,d.ondutyhhmm),'%Y%m%d%H:%i') stdON
,str_to_date(concat(b.dutydate,d.offdutyhhmm),'%Y%m%d%H:%i')
 +interval offnext*24*60 minute stdOff
,str_to_date(concat(b.dutydate,d.oversthhmm),'%Y%m%d%H:%i')
 +interval overnext*24*60 minute OverOn
,d.buffermm
,str_to_date(concat(b.dutydate, d.ondutyhhmm),'%Y%m%d%H:%i') 
 + interval -( d.RangeSt) minute RangeST
,str_to_date(concat(b.dutydate,d.offdutyhhmm),'%Y%m%d%H:%i') 
 + interval offnext*24*60+(d.RangeEnd) minute RangeEND
from tperson a
left join tdepsch b on a.ouguid=b.ouguid and b.depguid=a.depguid
left join tempsch c on a.ouguid=b.ouguid and c.empguid=a.empguid and b.dutydate=c.dutydate
left join tworkinfo d on a.ouguid=d.ouguid and d.workguid=ifnull(c.workguid,b.workguid)
where 
    b.dutydate>=a.arrivedate # 到職後才要出勤
and b.dutydate<=Case When a.leavedate>0 Then a.leavedate Else 29991231 end #離職前要出勤
and b.dutydate<=Case When  a.stopdate>0 Then  a.stopdate Else 29991231 End #留停前要出勤
#and b.dutydate between 20130404 and 20130404
#and a.cardno='a00920'
;
 

select * from tworkinfo;