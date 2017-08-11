delimiter $$

use csr_system$$ 

CREATE TABLE if not exists `tmemoTables` (
  `rwid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ltdate` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ltpid` varchar(50) DEFAULT NULL,
  `crdate` datetime DEFAULT CURRENT_TIMESTAMP,
  `cruser` varchar(50) DEFAULT NULL,
  `Table_schema` varchar(64) NOT NULL DEFAULT '',
  `Table_name` varchar(64) NOT NULL DEFAULT '',
  `Table_Desc` varchar(36) DEFAULT NULL,
  `Table_Memo` text,
  `life` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`rwid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8$$


insert into tmemoTables  (Table_schema,Table_name)
select a.Table_schema,a.Table_name
from information_schema.Tables a
left join tmemoTables b on a.Table_schema=b.Table_schema and a.Table_name=b.Table_name
where a.table_schema='csrhr' and  b.Table_name is null$$

