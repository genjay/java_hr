select sum(off_mins_left) from vOvertooff_status a
Where 
a.Off_Mins_Left > 0
and a.empGuid='C153AE60-B2A2-4300-BB33-48374A98E79F'
and a.OverEnd < '2014-05-12 04:00' /*請假起*/
and a.Valid_end > '2014-05-12 04:00' /*請假起，不是迄*/;

 