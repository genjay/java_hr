select concat("alter table ",table_schema,'.',table_name,'\n'
,'drop column ',column_name,';')
from information_schema.columns
where column_name in ('cruser','crdate','ltuser','ltdate','ltpid','sec_ltuser','sec_ltpid','sec_ltdate')