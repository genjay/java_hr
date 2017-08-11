drop procedure if exists p_tOffDoc_02;

delimiter $$

create procedure p_tOffDoc_02 
(
 in_OffDocRWID int
)
begin
 # 處理請補休時，加班及請假對應部份 tOverToOff_used

delete from tovertooff_used 
Where OffDocGuid = (select OffDocGuid from tOffDoc b Where b.rwid=in_OffDocRWID);
 
set @tmp_loop=1;

While @tmp_loop >=1 Do
 /*此對應sql，無法一次產生所有資料
 需要多次執行，到沒有資料需要在新增*/
insert into tovertooff_used
(overdocguid,offdocguid,OffDoc_mins) 
select c.OverDocGuid,a.OffDocGuid  
,Case 
 When a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0) > Off_Mins_left
 Then Off_Mins_left
 Else a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0)
 End usede
from tOffDoc a
LEFT join vovertooff_matched_offdoc b on a.OffDocGuid=b.OffDocGuid
left join vOverToOff_Status c on a.empguid=c.empguid
 and a.OffDoc_start > c.OverEnd
 and a.OffDoc_start < c.Valid_End
Where a.rwid=in_OffDocRWID /*請假單RWID*/
 and a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0) > 0 /*待分配大於0，才要處理*/
 and Off_Mins_left > 0 /*還有可分配的，才要處理*/
order by c.Valid_End asc limit 1; 

/*用count(*)來判斷是否還有資料，需要新增*/
select count(*) into @tmp_loop 
from tOffDoc a
LEFT join vovertooff_matched_offdoc b on a.OffDocGuid=b.OffDocGuid
left join vOverToOff_Status c on a.empguid=c.empguid
 and a.OffDoc_start > c.OverEnd
 and a.OffDoc_start < c.Valid_End
Where a.rwid=in_OffDocRWID /*請假單RWID*/
 and a.OffDoc_Mins-IFNULL(Sum_OffDoc_Matched,0) > 0 /*待分配大於0，才要處理*/
 and Off_Mins_left > 0 /*還有可分配的，才要處理*/
order by c.Valid_End asc limit 1; 

end while;


end



;