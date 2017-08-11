call p_toffdoc_04b(
 (select empguid from tperson where empid='a00024' and ouguid='microjet')
,(select codeguid from tcatcode where codeid='OFF15')
,'2024-05-01 10:00:00' 
,'2024-06-25 17:20:00'
,16436
,@x
,@y
,@z
,@a
,@message);

select @x,@y,@z,@a,@message;