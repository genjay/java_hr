set @in_OUguid='microjet';

insert into tcatcode
(codeguid,OUguid,syscode,codeid,codedesc,codeseq,stop_used)
SELECT UUID(),@in_OUguid,Syscode,CodeID,CodeDesc,CodeSeq,stop_used 
FROM TCATCODE a WHERE SYSCODE LIKE 'z%'
 And Not exists (select * from tcatcode b Where a.syscode=b.syscode and a.codeid=b.codeid and b.OUguid=@in_OUguid);