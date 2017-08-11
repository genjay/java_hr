set @Table_name='tOUset_paybase';

# 宣告用
select concat(Rpad(concat(' in_OUguid '),30,' '),'varchar(36)') column_name union all
select concat(Rpad(concat(',in_LtUser '),30,' '),'varchar(36)') column_name union all
select concat(Rpad(concat(',in_ltPid '),30,' '),'varchar(36)')  column_name union all
select concat(Rpad(concat(',in_',column_name),30,' '),replace(column_type,'bit','int'))  
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_schema=schema()
 and a.table_name = @Table_name
 and a.column_name not in (SELECT column_name FROM information_schema.STATISTICS
where table_schema=schema()
and index_name='upk'
and table_name=@Table_name)
and ((table_type='BASE TABLE' and column_name not in ('ouguid','ltuser','ltpid','ltdate'))  
or (b.table_type='VIEW' and not column_name in ('ouguid')))
;


# Insert 語法
select concat(
'if err_code=0 && in_Rwid=0 then # 90 新增\n'
,' Insert into ',@Table_name,'\n'
 ,'(ltUser,ltPid,'
 ,group_concat(column_name),')','\n'
 ,'values \n'
 ,'(in_ltUser,in_ltPid,',group_concat(concat('in_',column_name)),');\n'
 ,'set outMsg=concat(\'「\',in_Rwid,\'」\',\'新增完成\');\n'
 ,'set outRwid=last_insert_id();\n'
 ,'end if; # 90 '
 ) xx
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_schema=schema()
 and a.table_name = @Table_name
and ((table_type='BASE TABLE' and column_name not in ('rwid','ltuser','ltpid','ltdate'))  
or (b.table_type='VIEW' and not column_name in ('ouguid')))
;


# update 語法
select concat(
 ' if err_code=0 && in_Rwid>0 then # 90 修改 \n'
,'Update ',@Table_name,' Set\n '
,group_concat(concat(Rpad(column_name,30,' '),'= in_',column_name,'\n'))
,' Where rwid=in_Rwid;\n'
,'set outMsg=concat(\'「\',in_Rwid,\'」\',\'修改成功\');\n'
,'set outRwid=in_Rwid;\n'
,'end if; # 90 修改\n'
) xx
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_schema=schema()
 and a.table_name = @Table_name
 and a.column_name not in (SELECT column_name FROM information_schema.STATISTICS
where table_schema=schema()
and index_name='upk'
and table_name=@Table_name)
and ((table_type='BASE TABLE' and column_name not in ('rwid','ouguid','ltdate'))  
or (b.table_type='VIEW' and not column_name in ('ouguid')))
;


# 判斷有無修改語法
select concat(
 'if err_code=0 then # 判斷是否有無修改\n'
,' set isCnt=0; \n'
,' Select rwid into isCnt \n '
,' From ',@table_name,' \n'
,' Where rwid=in_Rwid And '
,group_concat(concat(column_name,'=in_',column_name) SEPARATOR  ' And ')
,';\n'
,'if isCnt>0 then set err_code=1; set outMsg=\'資料無修改\'; end if;\n'
,'end if;'
) xx
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_schema=schema()
 and a.table_name = @Table_name
 and a.column_name not in (SELECT column_name FROM information_schema.STATISTICS
where table_schema=schema()
and index_name='upk'
and table_name=@Table_name)
and ((table_type='BASE TABLE' and column_name not in ('rwid','ouguid','ltdate','ltUser','ltPid'))  
or (b.table_type='VIEW' and not column_name in ('ouguid')))
;


# 產生儲存的log
select concat('Insert into tlog_proc (ltpid,note) values (','\'',column_name,'\',','in_',column_name,');')  
from information_schema.columns a
inner join information_schema.tables b on a.table_name=b.table_name and a.table_schema=b.table_schema
where a.table_schema=schema()
 and a.table_name = @Table_name
 and a.column_name not in (SELECT column_name FROM information_schema.STATISTICS
where table_schema=schema()
and index_name='upk'
and table_name=@Table_name)
and ((table_type='BASE TABLE' and column_name not in ('ouguid','ltuser','ltpid','ltdate'))  
or (b.table_type='VIEW' and not column_name in ('ouguid')))
;