
select concat("alter table ",table_name ,
" drop column cruser
,drop column crdate
,drop column ltpid   ;")
from information_schema.tables
where table_schema in ('csrhr')
and table_type='BASE TABLE';

select concat("alter table ",table_name ,
" drop column cruser
,drop column crdate
,drop column ltpid 
,add column  ltUser varchar(36) after ltdate
,add column  ltpid  varchar(36) after ltUser
,add column sec_ltdate datetime after ltpid
,add column  sec_ltUser varchar(36) after sec_ltdate
,add column  sec_ltpid  varchar(36) after sec_ltUser ;")
from information_schema.tables
where table_schema in ('csrhr')
and table_type='BASE TABLE';


select * from information_schema.tables
where table_schema in ('csrhr');