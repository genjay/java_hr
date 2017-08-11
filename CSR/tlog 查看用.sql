Select a.rwid,a.ltpid,a.note,a.ltdate,b.ltdate
,timediff(a.ltdate,b.ltdate)
from t_log a
left join t_log B on b.rwid=(a.rwid-1) and a.connection_id=b.connection_id
where a.ltpid='ltpid'
order by a.rwid desc