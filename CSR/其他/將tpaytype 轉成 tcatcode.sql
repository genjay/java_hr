insert into tcatcode
(codeguid,codedesc,codeid,syscode,ouguid,codeseq) 
SELECT paytypeguid,paytypedesc,concat('P',lpad((@rownum:=@rownum+1),2,'0'))
,'A06' syscode,'default' ouguid,@rownum
FROM csrhr.tpaytype
left join (select @rownum:=( 
select cast(max(substring(codeid,2,3)) as decimal(10,0)) from tcatcode
where syscode='a06' 
) ) b on 1=1
where not paytypeguid in (select codeguid from tcatcode);
 