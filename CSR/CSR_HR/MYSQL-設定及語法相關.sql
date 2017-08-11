create temporary table tt2 engine=memory
select * from tperson limit 1; # 建立memory 格式的temp table

select (data_length+index_length)/1024/1024 total_size,a.* 
from information_schema.tables a
where table_schema='csrhr'
and table_name in ('tt3','tt4'); #計算 table 大小

select @@max_heap_table_size/1024/1024; #(MB)engine=memory最大值

select @@tmp_table_size/1024/1024; #(MB) temp table max 

set max_heap_table_size=128*(1024*1024);# 128(MB)設定engine=memory 容量大小

set sql_safe_updates=0; #取消更新多筆資料限制

set innodb_flush_log_at_trx_commit=0; #取消innodb autocommit

select CONNECTION_ID(); #取得session ID

select user(); # 取得登入者帳號

SELECT CURRENT_USER(); #取得登入者帳號

SELECT FOUND_ROWS(); #取得上一筆查詢資料筆數

SELECT LAST_INSERT_ID();# (不會用)Value of the AUTOINCREMENT column for the last INSERT

select row_count();# (不會用) The number of rows updated

SELECT COLLATION(_big5'陳煜');#取得字串編碼格式

SELECT VERSION(); # 取得資料庫版本

SELECT BENCHMARK(1,ENCODE('hello','goodbye')); #測試效能相關

select benchmark(2,(select cardno from vdutystd limit 100000,1)); #測試效能相關
   
