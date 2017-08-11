
select empid,a.offtypeguid,c.quota_year
,Sum(a.Quota_OffMins)/60 Quota_hr  # 年度可用小時
,Sum(off_mins_left)/60   Left_hr   # 年度已用小時
from vOffquota_status a
left join tperson b on a.empguid=b.empguid
left join tOffquota c on a.QuotaDocGuid=c.QuotaDocGuid
where 1=1
group by empid,offtypeguid,c.quota_year;

select * from toffquota;