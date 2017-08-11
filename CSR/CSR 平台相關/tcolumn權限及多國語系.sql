set @LangID='en';
 
select a.column_name,a.column_desc
,Case 
 When Y.column_Desc is not null Then   Y.column_Desc  
 Else 'a.column_desc'
 End MutiDesc
,Case 
 When d.column_name is not null Then d.column_name
 When c.column_name is not null Then c.column_name
 When b.column_name is not null Then b.column_name
 else a.column_name
 end column_name
,Case 
 When d.mask is not null Then d.mask
 When c.mask is not null Then c.mask
 When b.mask is not null Then b.mask
 else a.mask
 end mask
,Case 
 When d.showtype is not null Then d.showtype
 When c.showtype is not null Then c.showtype
 When b.showtype is not null Then b.showtype
 else a.showtype
 end showtype
from tcolumn_secdd a
left join tcolumn_secpid b on a.column_name=b.column_name and b.pid=@pid
left join tcolumn_secrole c on a.column_name=c.column_name 
 and c.ouguid=@ouguid and c.pid=@pid
 and c.roleguid in (select roleguid from trolemember where empguid=@empguid)
left join tcolumn_secemp d on a.column_name=d.column_name
 and d.ouguid=@ouguid and d.pid=@pid 
 and d.empguid=@empguid
left join tcolumn_desc Y on a.column_name=Y.column_name and Y.langID=@langid;

select * from tcolumn_desc
where langid='en';