insert into tcatcode
(ouguid,codeguid,syscode,codeid,codeDesc,codeseq)
Select 'default',uuid(),syscode,codeid,codeDesc,codeseq
from tcatcode a
where syscode like 'z%'
and not exists (select * from tcatcode x where x.OUguid='default'
  and x.syscode=a.syscode and x.codeid=a.codeid)
group by syscode,codeid,codeDesc,codeseq