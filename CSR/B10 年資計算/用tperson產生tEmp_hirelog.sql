truncate temp_hirelog;
insert into temp_hirelog
(empguid,valid_date,type_z09,job_age_offset)
Select empguid,arrivedate,'A1',0 from tperson 
where ouguid='microjet'
and arrivedate>0;

insert into temp_hirelog
(empguid,valid_date,type_z09,job_age_offset)
Select empguid,leavedate,'Q1',0 from tperson
where ouguid='microjet'
and leavedate>0;

insert into temp_hirelog
(empguid,valid_date,type_z09,job_age_offset)
Select empguid,stopdate,'Q2',0 from tperson
where ouguid='microjet'
and stopdate>0;