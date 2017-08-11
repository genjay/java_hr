select sql_no_cache a.* from vdutystd a
left join tperson b on a.ouguid=b.ouguid and a.empguid=b.empguid
where b.ouguid='htc'
; # 第一種，速度 0.141

 select sql_no_cache b.* from tperson a
left join vdutystd b on a.ouguid=b.ouguid and a.empguid=b.empguid
where a.ouguid='htc'; #第二種 速度0.031 0.016 (快)

select (curdate()+interval 18 day)+0;

select floor((dtcardtime+0)/1000000) from tcardtime;