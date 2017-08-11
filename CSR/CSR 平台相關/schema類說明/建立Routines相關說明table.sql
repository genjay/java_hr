delimiter $$

use csr_system$$ 

CREATE TABLE if not exists `tmemoroutines` (
  `rwid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ltdate` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ltpid` varchar(50) DEFAULT NULL,
  `crdate` datetime DEFAULT CURRENT_TIMESTAMP,
  `cruser` varchar(50) DEFAULT NULL,
  `routine_schema` varchar(64) NOT NULL DEFAULT '',
  `routine_name` varchar(64) NOT NULL DEFAULT '',
  `routine_Desc` varchar(36) DEFAULT NULL,
  `routine_Memo` text,
  `life` varchar(36) DEFAULT NULL,
  PRIMARY KEY (`rwid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8$$


insert into tmemoroutines  (routine_schema,routine_name)
select a.routine_schema,a.routine_name
from information_schema.routines a
left join tmemoroutines b on a.routine_schema=b.routine_schema and a.routine_name=b.routine_name
where b.routine_name is null$$

