-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `P00004A`(
  varouguid varchar(36),varempguid varchar(36),varlandid varchar(36)
 ,out outSTRA text )
begin

/* 輸入相關資料，產出該帳號可使用的menu
 call p00004a('microjet','a00514','tw',@x);
*/

declare savep1 int; 
declare save_sql_safe_updates int;
declare save_max_heap_table_size int;
declare save_group_concat_max_len int;


drop table if exists tmpA_P00004;

create table tmpA_P00004 as
    select 
        a.mon_mid AS mon_mid,
        a.mid AS mid,
        a.pid AS pid,
        a.mdesc AS mdesc,
        a.sort AS sort,
        b.pid_whs AS pid_whs
    from
        tpid_menu a
        left join tpid_ctrl b ON a.pid = b.pid;

 alter table tmpA_P00004 add index i01 (pid) ;

drop table if exists tmpB_P00004;
create table tmpB_P00004 as
select  @rownum:=@rownum+1 rownum,a.* 
from (
select a.mdesc adesc,b.mdesc bdesc,c.mdesc cdesc,
        case
            when c.pid is not null then c.pid
            when b.pid is not null then b.pid
            else a.pid
        end AS pid,
        case
            when c.pid is not null then c.pid_whs
            when b.pid is not null then b.pid_whs
            else a.pid_whs
        end AS pid_whs
from tmpa_p00004 a 
left join tmpa_p00004 b on a.mid=b.mon_mid
left join tmpa_p00004 c on b.mid=c.mon_mid
where a.mon_mid='0'
order by a.sort ,b.sort,c.sort
) a,(SELECT @rownum := 0) b;

 alter table tmpB_P00004 add index i01 (pid) ;

drop table if exists tmpC_P00004;
create table tmpC_P00004 as
select a.adesc,a.bdesc,a.cdesc,a.pid,a.pid_whs
,IFNULL(b.runtype,c.runtype) runtype
-- ,rownum
FROM tmpb_p00004 a
left join tpid_secemp b on a.pid=b.pid  and b.empguid= varempguid
left join tpid_secrole c on a.pid=c.pid  
  and c.roleguid in (select roleguid from trolemember where empguid=varempguid)
where IFNULL(b.runtype,c.runtype)>0
order by rownum;

select 
group_concat(
concat(a.adesc,',',a.bdesc,',',a.cdesc,',',a.pid,',',a.pid_whs,',',a.runtype) SEPARATOR ',')
into outSTRA
from tmpc_p00004 a;



drop table if exists tmpA_P00004;
drop table if exists tmpB_P00004;
drop table if exists tmpC_P00004;

end