create or replace view vPid_sec as
Select a.Pid_id,a.pid_Desc,g.aid
,Case 
 When c.runtype is not null Then c.runtype
 When f.runtype is not null Then f.runtype
 Else 0
 End runtype
,Case 
 When c.runtype is not null Then 'tpid_secemp'
 When f.runtype is not null Then 'tpid_secrole'
 Else '沒設定'
 End runtype_s
,e.Role_ID
,e.OUguid
from tpid_ctrl a
left join tAccount_ou b on 1=1
left join tpid_secemp c on a.pid_ID=c.pid_ID and c.Aid_guid=b.Aid_guid
left join tRole_member d on b.Aid_guid=d.Aid_guid
left join tRole e on e.Role_guid=d.Role_Guid and e.ouguid=b.ouguid
left join tpid_secrole f on f.pid_id=a.pid_id and f.Role_guid=e.Role_guid
left join tAccount g on b.aid_guid=g.aid_guid;