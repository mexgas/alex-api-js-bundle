ALTER PROCEDURE [dbo].[ccspTimesOutboundData] @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#outboundData2', N'U') IS NOT NULL
	DROP TABLE #outboundData2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = 'tmpTimesOutboundData'
		)
BEGIN
	CREATE TABLE tmpTimesOutboundData (
		row INT identity
		,dateStartDetail DATETIME
		,dateEndDetail DATETIME
		,timegroup DATETIME
		,timegroup_next DATETIME
		,cam_id INT
		,User_id INT
		,ntotal INT
		,nno_agent INT
		,nxfer INT
		,nabnd_xfer INT
		,nabnd_ring INT
		,nno_answer INT
		,nabnd_dialog INT
		,nanswer INT
		,nlost INT
		,tque INT
		,txfer INT
		,tring INT
		,tdialog INT
		,tnotes INT
		,tresp INT
		,nhangup INT
		,nMoh INT
		,nWHag INT
		,nWHcl INT
		,time_endque DATETIME
		,time_ring DATETIME
		,time_dialog DATETIME
		,time_notes DATETIME
		,time_end_call DATETIME
		,phone_out VARCHAR(30)
		,cal_id INT
		,cal_puerto INT
		,idwg INT
		,statuscall_id INT
		,calif_id INT
		,cal_manual int
		,cal_tMoh int
		)
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesOutboundData
		--drop table tmpTimesOutboundData
END

DECLARE @relastionCampWg TABLE (
	idwg INT
	,camId INT
	)

INSERT INTO @relastionCampWg
SELECT max(IDWG) AS IDWG
	,IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 1
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT

SELECT @HourExtend = 2

DECLARE @fromExtended AS SMALLDATETIME

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH TimesOutboundData
AS (
	SELECT cal_Inicio AS dateStartDetail
		,DATEADD(ss, isnull((cal_txfer + cal_tring + cal_tdialog + cal_tnotas), 0), cal_Inicio) AS dateEndDetail
		,cam_id
		,[User_id]
		,1 AS ntotal
		,CASE WHEN (statuscall_id = 4) THEN 1 ELSE 0 END AS nno_agent
		,CASE WHEN (statuscall_id >= 10) THEN 1 ELSE 0 END AS nxfer
		,CASE WHEN (statuscall_id = 11) THEN 1 ELSE 0 END AS nabnd_xfer
		,CASE WHEN (
					statuscall_id = 15
					AND cal_tring <= @tresRing
					) THEN 1 ELSE 0 END AS nabnd_ring
		,CASE WHEN (
					statuscall_id = 15
					AND cal_tring > @tresRing
					) THEN 1 ELSE 0 END AS nno_answer
		,CASE WHEN (
					statuscall_id = 13
					AND cal_tdialog <= @tresDialog
					) THEN 1 ELSE 0 END AS nabnd_dialog
		,CASE WHEN (
					statuscall_id = 13
					AND cal_tdialog > @tresDialog
					) THEN 1 ELSE 0 END AS nanswer
		,CASE WHEN (statuscall_id = 16) THEN 1 ELSE 0 END AS nlost
		,cal_twait AS tque
		,cal_txfer AS txfer
		,cal_tring AS tring
		,cal_tdialog AS tdialog
		,cal_tnotas AS tnotes
		,CASE WHEN (
					statuscall_id = 13
					AND cal_tdialog > @tresDialog
					) THEN (cal_txfer + cal_tring) ELSE 0 END AS tresp
		,CASE WHEN (statuscall_id = 6) THEN 1 ELSE 0 END AS nhangup
		,CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
		,CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
		,CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
		,DATEADD(ss, cal_twait, cal_inicio) AS time_endque
		,DATEADD(ss, cal_twait + cal_txfer, cal_inicio) AS time_ring
		,DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio) AS time_dialog
		,DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio) AS time_notes
		,DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio) AS time_end_call
		,cal_telefono AS phone_out
		,cal_id
		,cal_puerto
		,B.idwg AS idwg
		,A.statuscall_id
		,A.calif_id
		,A.cal_manual
		,A.cal_tMoh
	FROM ccoCallsOut A WITH (NOLOCK)
	LEFT JOIN @relastionCampWg B ON A.cam_id = B.camId
	WHERE cal_Inicio >= @fromExtended
		AND cal_inicio < @to
		--AND cal_manual IN (0, 2, 3)
	)
INSERT INTO tmpTimesOutboundData (
	dateStartDetail
	,dateEndDetail
	,cam_id
	,User_id
	,ntotal
	,nno_agent
	,nxfer
	,nabnd_xfer
	,nabnd_ring
	,nno_answer
	,nabnd_dialog
	,nanswer
	,nlost
	,tque
	,txfer
	,tring
	,tdialog
	,tnotes
	,tresp
	,nhangup
	,nMoh
	,nWHag
	,nWHcl
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_out
	,cal_id
	,cal_puerto
	,idwg
	,statuscall_id
	,calif_id
	,cal_manual
	,cal_tMoh
	,timegroup
	,timegroup_next
	)
SELECT A.*
	,dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
	,dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
FROM TimesOutboundData A

IF CONVERT(DATE, @dateNow, 121) = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId
			,max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN convert(DATE, @to, 121)
				AND @to
		GROUP BY userId
		)
		,timeAcumlate
	AS (
		SELECT A.userId
			,A.camId
			,A.callId
			,sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus ELSE 0 END) AS tdialog
			,sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes
			,max(A.dateEnd) AS dateEnd
			,max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN convert(DATE, @to, 121)
				AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 1
		GROUP BY A.userId
			,A.camId
			,A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd
		,A.timegroup_next = B.timeGroupNext
		,A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.tdialog END
		,A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END
		,A.time_notes = CASE WHEN B.tdialog > 0 THEN B.dateEnd ELSE A.time_dialog END
		,A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
	FROM tmpTimesOutboundData A
	INNER JOIN timeAcumlate B ON A.User_id = B.userId
		AND A.cam_id = B.camId
		AND A.cal_id = B.callId
END

SELECT *
INTO #outboundData2
FROM tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

DELETE tmpTimesOutboundData
WHERE datediff(mi, timegroup, timegroup_next) > 15

INSERT INTO tmpTimesOutboundData (
	dateStartDetail
	,dateEndDetail
	,timegroup
	,timegroup_next
	,cam_id
	,User_id
	,ntotal
	,nno_agent
	,nxfer
	,nabnd_xfer
	,nabnd_ring
	,nno_answer
	,nabnd_dialog
	,nanswer
	,nlost
	,tque
	,txfer
	,tring
	,tdialog
	,tnotes
	,tresp
	,nhangup
	,nMoh
	,nWHag
	,nWHcl
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_out
	,cal_id
	,cal_puerto
	,idwg
	,statuscall_id
	,calif_id
	,cal_manual
	,cal_tMoh
	)
SELECT dateStartDetail
	,dateEndDetail
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,cam_id
	,[User_id]
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ntotal ELSE 0 END AS ntotal
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nxfer ELSE 0 END AS nxfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nanswer ELSE 0 END AS nanswer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nlost ELSE 0 END AS nlost
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
	,dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer
	,dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
	,dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
	,dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, dateadd(ss, tresp, dateStartDetail)) AS tresp
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nhangup ELSE 0 END AS nhangup
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nMoh ELSE 0 END AS nMoh
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHag ELSE 0 END AS nWHag
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_out
	,cal_id
	,cal_puerto
	,idwg
	,statuscall_id
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id
	,cal_manual
	,dbo.AccountInterval(th.start,th.stop,dateStartDetail,dateEndDetail,cal_tMoh) as cal_tMoh
FROM #outboundData2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timegroup_next
WHERE datediff(ss, th.start, timegroup_next) > 0

IF OBJECT_ID(N'tempdb..#outboundData2', N'U') IS NOT NULL
	DROP TABLE #outboundData2