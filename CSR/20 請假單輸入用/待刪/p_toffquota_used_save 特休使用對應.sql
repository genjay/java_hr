drop procedure if exists p_toffquota_used_save;

delimiter $$ 

create procedure p_toffquota_used_save(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid varchar(36) /*程式代號*/
,in_RWID int
)
begin

 # 產生特休類的使用對應紀錄
set @in_OUguid = in_OUguid;
set @in_ltUser = in_ltUser;
set @in_ltpid = if(trim(in_ltpid)='','p_toffquota_used_save',in_ltpid);
set @in_RWID=in_RWID;
 

set @tmp_loop=1;

While @tmp_loop >=1 Do
 /*此對應sql，無法一次產生所有資料
 需要多次執行，到沒有資料需要在新增*/
insert into `toffquota_used`
(ltuser,ltpid,Quotadocguid,offdocguid,OffDoc_mins) 
select @in_ltUser,@in_ltpid,c.QuotaDocGuid,a.OffDocGuid  
,Case 
 When a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0) > Off_Mins_left
 Then Off_Mins_left
 Else a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0)
 End usede
from tOffDoc a
LEFT join voffquota_matched_offdoc b on a.OffDocGuid=b.OffDocGuid
left join vOffquota_status c on a.empguid=c.empguid
inner join tOfftype d on a.offtypeguid=d.offtypeguid 
 and a.OffDoc_start > c.Quota_Valid_ST
 and a.OffDoc_start < c.Quota_Valid_End
Where 1=1 
 and QuotaCtrl=1
 and a.rwid = @in_RWID /*請假單RWID*/
 and a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0) > 0 /*待分配大於0，才要處理*/
 and c.Off_Mins_left > 0 /*還有可分配的，才要處理*/
order by c.Quota_Valid_End asc limit 1; 

/*用count(*)來判斷是否還有資料，需要新增*/
select count(*) into @tmp_loop 
from tOffDoc a
LEFT join voffquota_matched_offdoc b on a.OffDocGuid=b.OffDocGuid
left join vOffquota_status c on a.empguid=c.empguid
inner join tOfftype d on a.offtypeguid=d.offtypeguid 
 and a.OffDoc_start > c.Quota_Valid_ST
 and a.OffDoc_start < c.Quota_Valid_End
Where a.rwid=in_RWID /*請假單RWID*/ 
 and QuotaCtrl=1 # 只處理特補休
 and a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0) > 0 /*待分配大於0，才要處理*/
 and c.Off_Mins_left > 0 /*還有可分配的，才要處理*/
order by c.Quota_Valid_End asc limit 1; 

end while;


end



;
  