SELECT * FROM csr_memo.ttables_memo a
Where exists 
(select * from information_schema.tables b where a.table_schema=b.table_schema
 and a.table_name=b.table_name)

ORDER BY 3;

select rwid from vtables_memo;