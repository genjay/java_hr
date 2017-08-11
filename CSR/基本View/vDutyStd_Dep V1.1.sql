CREATE  or replace
VIEW vdutystd_dep AS 
    select 
        a.OUguid AS OUguid,
        a.CodeID AS DepID,
        a.CodeDesc AS DepDesc,
        a.CodeGuid AS DepGuid,
        b.CalDate AS Dutydate,
        (case
            when (ifnull(c.Holiday, '') <> '') then c.Holiday
            when (ifnull(b2.holiday, '') <> '') then b2.holiday
            else b.holiday
        end) AS Holiday,
        (case
            when (ifnull(c.WorkGuid, '') <> '') then c.WorkGuid
            when (ifnull(d.WorkGuid, '') <> '') then d.WorkGuid
            else e.WorkGuid
        end) AS WorkGuid,
        h.CodeID AS WorkID,
        (str_to_date(concat(b.CalDate, g.OnDutyHHMM),
                '%Y-%m-%d%H:%i:%s') + interval g.OnNext_Z04 day) AS std_ON,
        (str_to_date(concat(b.CalDate, g.OffDutyHHMM),
                '%Y-%m-%d%H:%i:%s') + interval g.OffNext_Z04 day) AS std_OFF
    from
        tcatcode a
        left join tcalendar b ON b.CalGuid = 'default'
        left join tcalendar b2 ON b2.CalGuid = a.OUguid and b.CalDate = b2.CalDate
        left join tschdep c ON b.CalDate = c.dutydate   and c.DepGuid = a.CodeGuid
        left join tdepartment d ON d.DepGuid = a.CodeGuid
        left join touset e ON e.OUguid = a.OUguid
        left join tworkinfo g ON g.WorkGuid = case
            when ifnull(c.WorkGuid, '') <> '' then c.WorkGuid
            when ifnull(d.WorkGuid, '') <> '' then d.WorkGuid
            else e.WorkGuid end
        left join tcatcode h ON h.CodeGuid = g.WorkGuid
    where
        a.SysCode = 'A07'