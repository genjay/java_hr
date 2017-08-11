drop table if exists tmp_emp;
create temporary table tmp_emp (empid int) engine=myisam;

insert into tmp_emp (empid)
Select @seq:=@seq+1
from csrhr.tcardtime a
left join (select @seq:=0) b on 1=1
limit 100000;

alter table tmp_emp add unique index i_empid (empid);

drop table if exists tmp01;

# tmpXX 產生26欄位的table 
drop table if exists tmpxx;
create temporary table tmpxx (col_type varchar(36),col_value int);

insert into tmpxx (col_type,col_value) values
('col_01',01),('col_02',02),('col_03',03),('col_04',04),('col_05',05),('col_06',06),('col_07',07),('col_08',08),('col_09',09),('col_10',10),('col_11',11),('col_12',12),('col_13',13),('col_14',14),('col_15',15),('col_16',16),('col_17',17),('col_18',18),('col_19',19),('col_20',20),('col_21',21),('col_22',22),('col_23',23),('col_24',24),('col_25',25),('col_26',26);

# ------------
create temporary table tmp01  
Select a.empid,20140501 dutydate,b.col_type,b.col_value
from tmp_emp a
left join tmpXX b on 1=1 ;
 
-- alter table tmp01 add index i_empid (empid); 

-- alter table tmp01 drop index i_empid;

select count(*)/10000 from tmp01;

drop table if exists tmp02;

CREATE temporary TABLE `tmp02` (
  `rwid` int(10) unsigned NOT NULL AUTO_INCREMENT ,
 empid int
,col_01 int default 1,
col_02 int default 2,
col_03 int default 3,
col_04 int default 4,
col_05 int default 5,
col_06 int default 6,
col_07 int default 7,
col_08 int default 8,
col_09 int default 9,
col_10 int default 10,
col_11 int default 11,
col_12 int default 12,
col_13 int default 13,
col_14 int default 14,
col_15 int default 15,
col_16 int default 16,
col_17 int default 17,
col_18 int default 18,
col_19 int default 19,
col_20 int default 20,
col_21 int default 21,
col_22 int default 22,
col_23 int default 23,
col_24 int default 24,
col_25 int default 25,
col_26 int default 26,
  PRIMARY KEY (`rwid`) 
);

insert into tmp02 (empid)
select empid from tmp_emp;