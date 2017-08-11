insert into ttables_memo
(table_schema,table_name)
SELECT a.table_schema,a.table_name
FROM csr_memo.vtables_memo a
left join ttables_memo b on a.rwid=b.rwid
where b.rwid is null;

select * from ttables_memo;

select * from vtables_memo;