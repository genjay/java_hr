select b.empguid,b.offtypeguid,year_offDays,sum(a.offMins )/60/8
from toffdoc_duty a
left join toffdoc b on a.offdocguid=b.offdocguid
left join tofftype c on a.offtypeguid=c.offtypeguid
where 
    a.dutydate between 20140101 and 20141231
and b.offtypeguid='BDB29668-521D-4AB1-87EA-248F76F8448D'
and b.empguid='84E28586-5E9C-4DA5-86F7-35D74FD19B00'
group by b.empguid,b.offtypeguid,year_offDays;