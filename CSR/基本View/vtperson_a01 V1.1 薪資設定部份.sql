create or replace view vtperson_a01 as 
Select a.OUguid,a.EmpID,a.EmpName
,b.codeid depID,b.codedesc depName
,if(ifnull(a02.codeid,'')='',a02d.codeid,a02.codeid) type_a02
,if(ifnull(a.type_Z15,'')='',z15.codeid,a.type_z15) type_z15
,if(ifnull(a.type_Z16,'')='',z16.codeid,a.type_z16) type_z16
,if(ifnull(a.type_Z17,'')='',z17.codeid,a.type_z17) type_z17 
,Case When ifnull(a.type_z15,'')='' Then c.Welfare_Rate 
 else a.Welfare_Rate end Welfare_Rate
,Case When ifnull(a.type_z15,'')='' Then c.Tax1_Rate 
 else a.Tax1_Rate end  Tax1_Rate
from tperson a
left join tcatcode b   on a.depguid=b.codeguid
left join tOUset   c   on c.OUguid=a.OUguid 
left join tcatcode A02 on A02.codeguid=a.overtypeguid
left join tcatcode A02d on A02d.OUguid=a.OUguid and a02d.syscode='A02'
 and a02d.default=1
left join tcatcode z15 on z15.OUguid=a.OUguid and z15.Syscode='Z15' 
 and z15.default=1 
left join tcatcode z16 on z16.OUguid=a.OUguid and z16.Syscode='Z16' 
 and z16.default=1 
left join tcatcode z17 on z17.OUguid=a.OUguid and z17.Syscode='Z17' 
 and z17.default=1 
