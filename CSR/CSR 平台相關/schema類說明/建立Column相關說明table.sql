delimiter $$

use csr_system$$ 

CREATE TABLE if not exists `tmemoColumns` (
  `rwid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ltdate` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ltpid` varchar(50) DEFAULT NULL,
  `crdate` datetime DEFAULT CURRENT_TIMESTAMP,
  `cruser` varchar(50) DEFAULT NULL,
  `Table_schema` varchar(64) NOT NULL DEFAULT '',
  `Table_name` varchar(64) NOT NULL DEFAULT '',
  `Column_name` varchar(36) DEFAULT NULL,
  `Column_Desc` varchar(64) DEFAULT NULL,
  `Column_Memo` text,
  `life` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`rwid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8$$
 

insert into tmemoColumns  (Table_schema,Table_name,Column_name)
select a.Table_schema,a.Table_name,a.Column_name
from information_schema.Columns a
left join tmemoColumns b on a.Column_name=b.Column_name 
  and a.Table_schema=b.Table_schema and a.Table_name=b.Table_name
where a.Table_schema='csrhr' and b.Column_name is null$$

