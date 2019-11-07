CREATE procedure ccspCheckIn as
select 
--sum(x.nxfer), sum(y.nxfer) 
*, x.nxfer-y.nxfer
from
( 
 select convert(varchar(10), timegroup, 121) fecha, user_id
,sum(nxfer) nxfer
 from ccGenInCAll
 where  user_id > 0
 group by convert(varchar(10), timegroup, 121), user_id
-- order by convert(varchar(10), timegroup, 121), user_id
)x
full join (

 select convert(varchar(10), login, 121) as fecha, user_id
 ,sum(nxfer) nxfer
 from ccGenSessionInCall 
 group by convert(varchar(10), login, 121), user_id
 
)y
on x.user_id = y.user_id and x.fecha = y.fecha
where x.nxfer> y.nxfer
order by x.fecha desc , 7 desc, x.user_id