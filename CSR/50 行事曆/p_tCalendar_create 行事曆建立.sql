drop procedure if exists p_tCalendar_create;

delimiter $$

Create procedure p_tCalendar_create(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Type   varchar(36)
,in_Year   year
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
 '',
 '2014',
 @a,@b,@c);

*/
declare tlog_note text; 
declare in_CalGuid varchar(36);
declare droptable int default 0;
declare isCnt int;  
set err_code=0;

set tlog_note= concat("call p_tCalendar_create(\n'"
,in_OUguid         ,"',\n'"
,in_ltUser         ,"',\n'"
,in_ltpid          ,"',\n'"    
,in_Type           ,"',\n'"    
,in_Year           ,"',\n"   
,'@a'              ,","
,'@b'              ,","
,'@c' 
,");");

call p_tlog(in_ltpid,tlog_note);
set outMsg='p_tCalendar_create,開始'; 

if err_code=0 then # 05 判斷日期合理性
  if year(now()+interval 3 month) < in_Year Then set err_code=1; set outMsg='離現在太久，不會新增'; end if;
end if; # 05

if err_code=0 Then # 10 產生 1~370 流水號 Table
  drop table if exists tmp01;
CREATE TABLE `tmp01` (
    `SEQ` int NOT NULL
)  ENGINE=MyisAm DEFAULT CHARSET=utf8;
  insert into tmp01 (SEQ) Values
  (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),(41),(42),(43),(44),(45),(46),(47),(48),(49),(50),(51),(52),(53),(54),(55),(56),(57),(58),(59),(60),(61),(62),(63),(64),(65),(66),(67),(68),(69),(70),(71),(72),(73),(74),(75),(76),(77),(78),(79),(80),(81),(82),(83),(84),(85),(86),(87),(88),(89),(90),(91),(92),(93),(94),(95),(96),(97),(98),(99),(100),(101),(102),(103),(104),(105),(106),(107),(108),(109),(110),(111),(112),(113),(114),(115),(116),(117),(118),(119),(120),(121),(122),(123),(124),(125),(126),(127),(128),(129),(130),(131),(132),(133),(134),(135),(136),(137),(138),(139),(140),(141),(142),(143),(144),(145),(146),(147),(148),(149),(150),(151),(152),(153),(154),(155),(156),(157),(158),(159),(160),(161),(162),(163),(164),(165),(166),(167),(168),(169),(170),(171),(172),(173),(174),(175),(176),(177),(178),(179),(180),(181),(182),(183),(184),(185),(186),(187),(188),(189),(190),(191),(192),(193),(194),(195),(196),(197),(198),(199),(200),(201),(202),(203),(204),(205),(206),(207),(208),(209),(210),(211),(212),(213),(214),(215),(216),(217),(218),(219),(220),(221),(222),(223),(224),(225),(226),(227),(228),(229),(230),(231),(232),(233),(234),(235),(236),(237),(238),(239),(240),(241),(242),(243),(244),(245),(246),(247),(248),(249),(250),(251),(252),(253),(254),(255),(256),(257),(258),(259),(260),(261),(262),(263),(264),(265),(266),(267),(268),(269),(270),(271),(272),(273),(274),(275),(276),(277),(278),(279),(280),(281),(282),(283),(284),(285),(286),(287),(288),(289),(290),(291),(292),(293),(294),(295),(296),(297),(298),(299),(300),(301),(302),(303),(304),(305),(306),(307),(308),(309),(310),(311),(312),(313),(314),(315),(316),(317),(318),(319),(320),(321),(322),(323),(324),(325),(326),(327),(328),(329),(330),(331),(332),(333),(334),(335),(336),(337),(338),(339),(340),(341),(342),(343),(344),(345),(346),(347),(348),(349),(350),(351),(352),(353),(354),(355),(356),(357),(358),(359),(360),(361),(362),(363),(364),(365),(366),(367),(368),(369),(370);
  set outMsg='10 產生tmp01';
end if;

if err_code=0 Then # 20 產生tmp02
 drop table if exists tmp02;
 create temporary table tmp02 as
 select str_to_date(concat(in_Year,'0101'),'%Y%m%d')+interval SEQ day CalDate
 ,IF(dayofweek(str_to_date(concat(in_Year,'0101'),'%Y%m%d')+interval SEQ day) in (1,7),1,0)  holiday
 from tmp01 a;
 alter table tmp02 add index i01 (Caldate);
 set outMsg='20 產生tmp02';
 if droptable=1 Then drop table if exists tmp01; end if;
end if; # 20 產生tmp02

if err_code=0 Then # 25 抓CalGuid
  set outMsg='25 抓CalGuid';
  IF IFNULL(in_Type,'')='' THEN # 25-1
   Select OUguid into in_CalGuid from tOUset Where OUguid=in_OUguid;
   if in_CalGuid='' Then set err_code=1; set outMsg='in_OUguid 不存在於tOUset'; end if;
  Else
   Select CodeGuid into in_CalGuid from tcatcode 
   where syscode='A05' and codeID=in_Type and ouguid=in_OUguid limit 1;
   if in_CalGuid='' Then set err_code=1; set outMsg="in_Type 不存在於tcatcode 'A05'"; end if;
  end if; # 25-1
end if; # 25 

if err_code=0 Then # 30
  drop table if exists tmp03;
  create temporary table tmp03 as 
  Select in_CalGuid CalGuid,a.Caldate
  ,Case
   When IFNULL(B.holiday,'')!='' THEN B.holiday
   Else a.holiday End holiday
  from tmp02 a
  left join tCalendar B on A.Caldate=B.Caldate And B.Calguid =(Select CodeGuid From tCatCode Where Syscode='A05' And OUguid='default' limit 1) 
  Where Year(a.Caldate)=in_Year;
   if droptable=1 Then drop table if exists tmp02; end if;
end if;

if err_code=0 Then # 90 只要新增，若已有資料，不要修改
  insert into tCalendar
  (ltUser,ltPid,CalGuid,Caldate,holiday)
  Select 'System Auto','p_tCalendar_create',CalGuid,CalDate,Holiday
  from tmp03 a
  Where Not exists (select * from tCalendar X Where a.Calguid=X.Calguid And a.Caldate=X.Caldate);
  if droptable=1 then drop table if exists tmp03; end if;
end if; # 90

end # Begin