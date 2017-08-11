drop procedure if exists p_tOUset_Calendar_create;

delimiter $$

Create procedure p_tOUset_Calendar_create(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)   
,in_Year   int   # 宣告year 只能到 2931，所以用int，可至9999
,out outMsg text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)
begin
/*
call p_tCalendar_create(
 'microjet',
 'ltUser',
 'ltPid', 
 '2014',
 @a,@b,@c);

*/

declare droptable int default 0;
declare isCnt int;  
declare Year_days int;
declare Not_need int default 0;
set err_code=0;
 
 
set outMsg='p_tCalendar_create,開始'; 
/*
if err_code=0 && year(now()+interval 3 month) < in_Year  then # 05 判斷日期合理性
 set err_code=1; set outMsg='離現在太久，不會新增';  
end if; # 05
*/

/*        因此曆法學家便重新規定閏年的規則為：西元年份

逢4的倍數閏， 例如：西元1992、1996年等，為4的倍數，故為閏年。

逢100的倍數不閏， 例如：西元1700、1800、1900年，為100的倍數，當年不閏年。

逢400的倍數閏， 例如：西元1600、2000、2400年，為400的倍數，有閏年

逢4000的倍數不閏， 例如：西元4000、8000年，不閏年。
*/
case
When mod(in_Year,4000)=0 then set Year_days=365; # 逢4000的倍數不閏
When mod(in_Year,400 )=0 then set Year_days=366; # 逢 400的倍數閏
When mod(in_Year,100 )=0 then set Year_days=365; # 逢 100的倍數不閏
When mod(in_Year,4   )=0 then set Year_days=366; # 逢   4的倍數閏
Else set Year_days=365; # 其他不閏
end case;

if err_code=0 then
 set isCnt=0;
 Select count(*) into isCnt from touset_calendar
 Where OUguid=in_OUguid and year(caldate)=in_Year;
 if isCnt=Year_days then set Not_need=1; set outMsg='不需新增'; end if;
end if;

if Not_need=0 Then # 05 資料不齊時，才需執行
if err_code=0 Then # 10 產生 1~370 流水號 Table
  drop table if exists tmp01;
CREATE temporary TABLE `tmp01` (
    `SEQ` int NOT NULL
)  ENGINE=memory DEFAULT CHARSET=utf8;
  insert into tmp01 (SEQ) Values
  (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),(41),(42),(43),(44),(45),(46),(47),(48),(49),(50),(51),(52),(53),(54),(55),(56),(57),(58),(59),(60),(61),(62),(63),(64),(65),(66),(67),(68),(69),(70),(71),(72),(73),(74),(75),(76),(77),(78),(79),(80),(81),(82),(83),(84),(85),(86),(87),(88),(89),(90),(91),(92),(93),(94),(95),(96),(97),(98),(99),(100),(101),(102),(103),(104),(105),(106),(107),(108),(109),(110),(111),(112),(113),(114),(115),(116),(117),(118),(119),(120),(121),(122),(123),(124),(125),(126),(127),(128),(129),(130),(131),(132),(133),(134),(135),(136),(137),(138),(139),(140),(141),(142),(143),(144),(145),(146),(147),(148),(149),(150),(151),(152),(153),(154),(155),(156),(157),(158),(159),(160),(161),(162),(163),(164),(165),(166),(167),(168),(169),(170),(171),(172),(173),(174),(175),(176),(177),(178),(179),(180),(181),(182),(183),(184),(185),(186),(187),(188),(189),(190),(191),(192),(193),(194),(195),(196),(197),(198),(199),(200),(201),(202),(203),(204),(205),(206),(207),(208),(209),(210),(211),(212),(213),(214),(215),(216),(217),(218),(219),(220),(221),(222),(223),(224),(225),(226),(227),(228),(229),(230),(231),(232),(233),(234),(235),(236),(237),(238),(239),(240),(241),(242),(243),(244),(245),(246),(247),(248),(249),(250),(251),(252),(253),(254),(255),(256),(257),(258),(259),(260),(261),(262),(263),(264),(265),(266),(267),(268),(269),(270),(271),(272),(273),(274),(275),(276),(277),(278),(279),(280),(281),(282),(283),(284),(285),(286),(287),(288),(289),(290),(291),(292),(293),(294),(295),(296),(297),(298),(299),(300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(310),(311),(312),(313),(314),(315),(316),(317),(318),(319),(320),(321),(322),(323),(324),(325),(326),(327),(328),(329),(330),(331),(332),(333),(334),(335),(336),(337),(338),(339),(340),(341),(342),(343),(344),(345),(346),(347),(348),(349),(350),(351),(352),(353),(354),(355),(356),(357),(358),(359),(360),(361),(362),(363),(364),(365),(366),(367),(368),(369),(370);
  set outMsg='10 產生tmp01';
end if; # 10 

if err_code=0 Then # 20 產生tmp02
 drop table if exists tmp02;
 create temporary table tmp02 engine=memory as
 select str_to_date(concat(in_Year,'0101'),'%Y%m%d')+interval SEQ day CalDate
 ,IF(dayofweek(str_to_date(concat(in_Year,'0101'),'%Y%m%d')+interval SEQ day) in (1,7),1,0)  holiday
 from tmp01 a;
 alter table tmp02 add index i01 (Caldate);
 set outMsg='20 產生tmp02';
 if droptable=1 Then drop table if exists tmp01; end if;
end if; # 20 產生tmp02

if err_code=0   then # 90 新增不存在資料至 touset_calendar
insert into touset_calendar 
(OUguid,ltpid,ltUser,Caldate,Holiday)
select in_OUguid,in_ltPid,in_ltUser,a.CalDate,a.Holiday
from tmp02 a 
Where  year(a.CalDate)=in_Year and
 not exists (select * from touset_calendar x where x.OUguid=in_OUguid and a.CalDate=x.CalDate)
;
 if droptable=1 Then drop table if exists tmp02; end if;
set outMsg='行事曆新增完成';
set outRwid=0;
end if; # 90 

end if; # 05 資料不齊時，才需執行

end # Begin