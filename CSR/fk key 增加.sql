SELECT # drop foreign key
concat("ALTER TABLE ",
f_strIndex(id,'/',1),'.',f_strIndex(for_name,'/',2)
," DROP FOREIGN KEY ",f_strIndex(id,'/',2)
,';' ) 
 FROM information_schema.INNODB_SYS_FOREIGN a
where f_strIndex(id,'/',1)='csrhr';

Select concat( # 
 "Alter Table ",table_schema,'.',table_name 
," add CONSTRAINT ",'fk_',table_name
,"   FOREIGN KEY (",column_name,')'
," REFERENCES tcatcode ( codeGuid);"
)
from information_schema.STATISTICS
Where non_unique=0 and seq_in_index=1 and table_schema='csrhr'
and column_name like '%guid'
And not table_name like '%base'
and Not column_name ='codeguid'
and Not column_name like '%doc%'
and Not column_name in ('ouguid','empguid','forgetdocguid')
order by table_name;


Select concat( # 用欄位產生
 "Alter Table ",table_schema,'.',table_name 
," add CONSTRAINT ",'fk_',table_name
,"   FOREIGN KEY (",column_name,')'
," REFERENCES tcatcode ( codeGuid);"
)
from information_schema.columns
Where 1=1
and table_schema in ('csrhr') and table_name like 't%'
and column_name in (SELECT column_name FROM information_schema.STATISTICS )
and column_name like '%guid%'
and table_name not in ('tcatcode','tcatcode2','toverdoc','toffdoc','tforgetdoc')
and column_name not in ('OUguid','empguid','roleguid','OffDocguid','OverDocguid','quotadocguid','up_depguid')
and table_name in ('tcalendar','tcard_type','tdepartment','tforgettype','tofftype'
,'touset','tovertype','tovertype_base','tpaytype','tworkinfo');

 
