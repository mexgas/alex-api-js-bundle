CREATE PROCEDURE ccsp_repAgentCallsCamps
@sFini varchar(20),
@sFfin varchar(20)
AS
declare @FIni datetime
declare @FFin datetime
select @FIni=convert(datetime, @sFini, 101), @FFin=convert(datetime, @sFfin, 101)
(
select U.user_id, Nombres + ' '+ ApellidoPaterno + ' '+ ApellidoMaterno, I.descripcion, count(*)
from ccCallsIN C join ccUsers U on C.User_id = U.User_id
join ccInbound I on C.Inbound_id = I.Inbound_id
where cal_inicio >= @FIni
and  cal_inicio <= @FFin
--and C.statusCall_id in (13, 15, 16)
and C.statusCall_id =13
group by  U.user_id, Nombres, ApellidoPaterno, ApellidoMaterno, descripcion 
)
union 
(
select 'User'=U.user_id, Nombres + ' '+ ApellidoPaterno + ' '+ ApellidoMaterno, O.cam_descripcion, count(*)
from ccoCallsOut C join ccUsers U on C.User_id = U.User_id
join ccCamps O on C.cam_id = O.cam_id
where cal_inicio >= @FIni
and  cal_inicio <= @FFin
and C.statusCall_id =13
group by  U.user_id, Nombres, ApellidoPaterno, ApellidoMaterno, cam_descripcion 
)
--order by U.user_id, descripcion, Nombres, ApellidoPaterno
order by U.user_id, descripcion