ALTER TABLE `tworkrest` 
CHANGE COLUMN `ltdate` `ltdate` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
CHANGE COLUMN `crdate` `crdate` datetime null default current_timestamp ;

