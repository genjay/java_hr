use csrhr;

set sql_safe_updates=0;

update tcardtime set empguid=null,dutydate=null;

select * from tcardtime
where dutydate is null;

update tcardtime set empguid=
(select empid from tperson a
where a.cardno=tcardtime.cardno limit 0,1)
,dutydate=
(select s.dutydate from vdutystd s
where s.cardno=tcardtime.cardno and tcardtime.dtcardtime between s.rangest and s.rangeend
order by dutydate asc limit 0,1)
where empguid is null
order by rwid
limit 100;

 