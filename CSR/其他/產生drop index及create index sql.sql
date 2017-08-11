select  concat("alter table ",table_name," add ",ifnull("Unique",'')," index ",index_name,"(",index_seq,");")
from csr_memo.vindex_memo
where index_name='upk' 
order by table_name,index_name;

select  concat("alter table ",table_name," drop ",''," index ",index_name,";")
from csr_memo.vindex_memo
where index_name='upk'
order by table_name,index_name;