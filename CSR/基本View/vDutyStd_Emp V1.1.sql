create or replace view vdutystd_emp as
Select a.Ouguid,a.EmpID,a.EmpName,a.CardNo
,b.dutydate
,Case 
 When IFNULL(C.HOLIDAY,'')!='' THEN C.HOLIDAY
 ELSE B.HOLIDAY END HOLIDAY
,Case 
 When IFNULL(C.WorkGuid,'')!='' Then C.WorkGuid 
 Else B.WorkGuid End WorkGuid
,(str_to_date(concat(`b`.`Dutydate`, `g`.`OnDutyHHMM`),'%Y-%m-%d%H:%i:%s') 
  + interval `g`.`OnNext_Z04` day) AS `std_ON`
,(str_to_date(concat(`b`.`Dutydate`, `g`.`OffDutyHHMM`),'%Y-%m-%d%H:%i:%s')
  + interval `g`.`OffNext_Z04` day) AS `std_OFF`
,(str_to_date(concat(`b`.`Dutydate`, `g`.`OnDutyHHMM`),'%Y-%m-%d%H:%i:%s') 
  + interval `g`.`OnNext_Z04` day + interval -(`g`.`RangeSt`) minute) AS `Range_on`
,(str_to_date(concat(`b`.`Dutydate`, `g`.`OffDutyHHMM`),'%Y-%m-%d%H:%i:%s') 
  + interval `g`.`OffNext_Z04` day+ interval `g`.`RangeEnd` minute) AS `Range_off`
,g.delaybuffer
,g.workminutes
,H.codeID WorkID
,a.empguid
from tperson A
left join vDutyStd_Dep B On A.DepGuid=B.DepGuid
left join tSchEmp      C On A.EmpGuid=C.Empguid And B.Dutydate=C.Dutydate
left join tWorkinfo    G On G.WorkGuid=Case 
 When IFNULL(C.WorkGuid,'')!='' Then C.WorkGuid 
 Else B.WorkGuid End
left join tcatcode     H On H.codeGuid=G.WorkGuid
Where ifnull(a.arrivedate,'9999-12-31') <= B.dutydate
And ifnull(a.leavedate,'9999-12-31')>= B.dutydate
# stopdate 停用 And ifnull(a.stopdate ,'9999-12-31')>= B.dutydate
;

 