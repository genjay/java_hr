drop procedure if exists p_tEmp_hirelog_del; # 人員異動資料刪除

delimiter $$

create procedure p_tEmp_hirelog_del
(
 in_OUguid varchar(36)
,in_ltUser varchar(36)
,in_ltpid  varchar(36)  
,in_Rwid   int
,in_Note   text  
,out outMsg   text /*回傳訊息，直接給user看的*/
,out outRwid  int  /*重疊的請假單*/
,out err_code int /*成功失敗代碼*/
)

Begin
declare isCnt int;
declare in_Empguid     varchar(36);
declare in_Type_Z09    varchar(36);
declare in_Title_name  varchar(36);
declare in_date1 date;
declare in_date2 date;
  set err_code=0;
  set outRwid=in_Rwid;
  set outMsg='人員異動刪除中';

if err_code=0 Then # 10
  set isCnt=0; set outMsg='判斷是否最後一筆';
  Select rwid into isCnt from tEmp_hirelog 
  where Empguid = (select empguid from tEmp_hirelog where rwid=in_Rwid)
  order by Valid_Date desc,type_z09 desc limit 1;
  if isCnt!=in_Rwid Then set err_code=1; set outMsg='這不是最後一筆，不能刪除'; end if;
end if; # 10

if err_code=0 Then # 20 抓 Empguid

  Select Empguid into in_Empguid from tEmp_hirelog
  Where Rwid=in_Rwid; 
end if; # 20 
 
if err_code=0 Then # 90
 
  Delete from tEmp_hirelog Where rwid = in_Rwid;
  set outRwid=in_Rwid; set outMsg='刪除完成';
  
  set in_date1=null; set in_date2=null;

  Select Valid_Date into in_date1 # 最後的到職日
  From tEmp_hirelog 
  Where Empguid = in_Empguid And substring(type_z09,1,1)='A'
  order by Valid_date Desc,type_z09 desc limit 1;

  Select Valid_Date into in_date2 # 到職日後的離職日
  From tEmp_hirelog
  Where Empguid = in_Empguid And substring(type_z09,1,1)='Q'
  order by Valid_date Desc,type_z09 desc limit 1;

  Select Title_name into in_Title_name # 抓title_name
  From tEmp_hirelog
  Where Empguid = in_Empguid And substring(type_z09,1,1) in ('A','C')
  order by Valid_date Desc,type_z09 desc limit 1;

  update tperson set
   Arrivedate = in_date1
  ,Leavedate  = in_date2
  ,Title_name = in_Title_name
  Where Empguid = in_Empguid;

end if;


end # Begin