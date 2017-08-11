select * from tdd_memo;

insert into tdd_memo
(column_name)
select distinct a.column_name
from vcolumns_memo a
left join tdd_memo b on a.column_name=b.column_name
Where b.rwid is null;