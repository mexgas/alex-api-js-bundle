CREATE PROCEDURE ccsp_GetAllInfoEspecNew
@dia as varchar(11)
AS

select
		inbound_id, 
		calls = ISNULL(count(*), 0),
--		Abandon = ISNULL(count (case when statusCall_id in (4,6,7,8,15,16) then 1 else null end), 0),
		--Abandon = ISNULL(count (case when statusCall_id in (4,6) then 1 else null end), 0),
		abandon = isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0),
		callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0),
		OverFlowQueue = ISNULL(count (case when  statusCall_id =8 then 1 else null end), 0),
		OverFlowTimeOut = ISNULL(count (case when  statusCall_id =7 then 1 else null end), 0),
		Dialogs = ISNULL(count (case when  statusCall_id = 13  then 1 else null end), 0),
		DlgsAveTime= ISNULL(sum (case when  statusCall_id = 13 then cal_tDialog + cal_tNotas else 0 end), 0),
--		Dlgs35segs =ISNULL(count (case when  statusCall_id = 13 and cal_tdialog < 35 then 1 else null end), 0),
		QueueAveTime=ISNULL( avg( case when   cal_que > 0 then cal_tWait else null end), 0) 
		from ccCallsIn
		where cal_inicio > convert(datetime, @dia, 101)
		group by inbound_id