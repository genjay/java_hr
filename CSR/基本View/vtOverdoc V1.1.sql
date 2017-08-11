CREATE or replace 
VIEW `vtoverdoc` AS 
    select 
        `a`.`rwid` AS `rwid`,
        `b`.`OUguid` AS `ouguid`,
        `a`.`empGuid` AS `empguid`,
        `b`.`EmpID` AS `empid`,
        `b`.`EmpName` AS `empname`,
        concat(`e`.`CodeID`, ' ', `e`.`CodeDesc`) AS `depname`,
        `a`.`dutydate` AS `dutydate`,
Case When ifnull(f.holiday,'')!='' then f.holiday
else g.holiday end holiday,
        `a`.`overStart` AS `overStart`,
        `a`.`overEnd` AS `overEnd`,
        `a`.`OverMins_Before` AS `OverMins_before`,
        `a`.`Overmins_After` AS `OverMins_After`,
        `a`.`OverMins_Holiday` AS `OverMins_Holiday`,
        `a`.`note` AS `Note`,
        concat(`c`.`CodeID`, ' ', `c`.`CodeDesc`) AS `overtype`,
        `c`.`CodeID` AS `overtypeguid`,
        `c`.`CodeDesc` AS `codedesc`,
        `a`.`ltdate` AS `ltdate`,
        `d`.`Aid` AS `keyinID`,
        `a`.`OverDocGuid` AS `Overdocguid`
    from
        ((((`toverdoc` `a`
        left join `tperson` `b` ON ((`b`.`EmpGuid` = `a`.`empGuid`)))
        left join `tcatcode` `c` ON ((`c`.`CodeGuid` = `a`.`overTypeGuid`)))
        left join `taccount` `d` ON ((`d`.`Aid_Guid` = `a`.`ltUser`)))
        left join `tcatcode` `e` ON ((`e`.`CodeGuid` = `b`.`DepGuid`))
 left join tSchemp f On f.empguid=a.empguid and f.dutydate=a.dutydate
 left join tSchdep g On g.depguid=b.depguid and g.dutydate=a.dutydate
)