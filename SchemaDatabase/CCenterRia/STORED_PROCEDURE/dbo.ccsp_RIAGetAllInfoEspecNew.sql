CREATE PROCEDURE [dbo].[ccsp_RIAGetAllInfoEspecNew]
@User_id as smallint
AS
set nocount on
-- declare @tresDialog int
-- exec @tresDialog = ccspConfigTresDialog

select a.inbound_id, calls = ISNULL(count(*), 0), -- calls
abandon = isnull(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
OverFlowQueue = ISNULL(count (case when statusCall_id =8 then 1 else null end), 0),
OverFlowTimeOut = ISNULL(count (case when statusCall_id =7 then 1 else null end), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
Dialogs = ISNULL(count (case when statusCall_id = 13 then 1 else null end), 0), -- Answered
DlgsAveTime= ISNULL(sum (case when statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
QueueAveTime=ISNULL( avg( case when cal_que > 0 then cal_tWait else null end), 0) ,
another=0, --ISNULL(count (case when statusCall_id in(2, 3, 4, 11, 15, 16) then 1 else null end), 0), -- others
outOfSchedule=ISNULL(count (case when statusCall_id =2 then 1 else null end), 0), -- fuera de horario
outOfService=ISNULL(count (case when statusCall_id =3 then 1 else null end), 0), -- fuera de servicio
noAgentsLoggedIn=ISNULL(count (case when statusCall_id =4 then 1 else null end), 0), -- sin agentes firmados
assigned=ISNULL(count (case when statusCall_id =11 then 1 else null end), 0), -- asignada
assignedAndNotAnswered=ISNULL(count (case when statusCall_id =15 then 1 else null end), 0), -- asignada y no contestada
assignedAndTookLine=ISNULL(count (case when statusCall_id =16 then 1 else null end), 0), -- asignada y toma linea
shortCalls=0, --ISNULL(sum(case when cal_tDialog < @tresDialog then 1 else 0 end), 0)
onQueue = isnull(count(case when statusCall_id = 5 then 1 else null end), 0),
initCalls = cast(isnull(count(case when statusCall_id = 1 then 1 else null end), 0) as varchar(7))+'|'+
ISNULL((SELECT STUFF((SELECT '|' + cast(ci.cal_id as varchar(7))
            FROM ccCallsin ci (nolock) where cal_inicio > dateadd(mi,-5,getdate()) and ci.inbound_id=a.inbound_id
            FOR XML PATH('')) ,1,1,'')),'0')
from ccCallsIn a (nolock)
where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
group by a.inbound_id
set nocount off
return(0)