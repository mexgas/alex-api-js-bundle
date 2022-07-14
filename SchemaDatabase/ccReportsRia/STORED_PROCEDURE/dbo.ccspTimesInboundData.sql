CREATE PROCEDURE [dbo].ccspTimesInboundData @from AS SMALLDATETIME
	,@to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#inboundData', N'U') IS NOT NULL
	DROP TABLE #inboundData

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = 'tmpTimesInboundData'
		)
BEGIN
	CREATE TABLE tmpTimesInboundData (
		[row] INT
		,dateStartDetail DATETIME
		,dateEndDetail DATETIME
		,timegroup DATETIME
		,timegroup_next DATETIME
		,time_endque DATETIME
		,time_ring DATETIME
		,time_dialog DATETIME
		,time_notes DATETIME
		,time_end_call DATETIME
		,phone_in VARCHAR(40)
		,cal_id INT
		,dni_id INT
		,Inbound_id INT
		,[User_id] INT
		,ntotal INT
		,ninitial INT
		,nout_hour INT
		,nout_service INT
		,nabnd INT
		,nno_agent INT
		,nque INT
		,ntimeout INT
		,noverflow INT
		,nxfer INT
		,nxfer_que INT
		,nabnd_xfer INT
		,nabnd_ring INT
		,nno_answer INT
		,nabnd_dialog INT
		,nanswer INT
		,nlost INT
		,nmsg INT
		,nabnd_tres INT
		,nansw_tres INT
		,tque_max INT
		,tque INT
		,txfer INT
		,tdialog INT
		,tnotes INT
		,tring INT
		,tresp INT
		,nMoh INT
		,nWHag INT
		,nWHcl INT
		,statusCall_id INT
		,[dateTResp] DATETIME
		,[dateTACD] DATETIME
		,calif_id INT
		,cal_tMoh int
		,cal_puerto int
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesInboundData
		--drop table tmpTimesInboundData
END

DECLARE @relastionCampWg TABLE (
	idwg INT
	,camId INT
	)

INSERT INTO @relastionCampWg
SELECT MAX(IDWG) AS IDWG
	,IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 0
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

WITH inboundData
AS (
	SELECT ROW_NUMBER() OVER (
			ORDER BY cal_id ASC
			) AS Row#
		,CASE WHEN cal_Xfer IS NULL
				OR cal_Xfer = '1900-01-01 00:00:00' THEN cal_inicio ELSE cal_Xfer END AS dateStartDetail
		,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, CASE WHEN cal_Xfer IS NULL
					OR cal_Xfer = '1900-01-01 00:00:00' THEN cal_inicio ELSE cal_Xfer END) dateEndDetail
		,*
	FROM ccCallsIn
	WHERE cal_inicio >= @fromExtended
		AND cal_inicio < @to
		AND INBOUND_ID > 0
	)

INSERT INTO tmpTimesInboundData
SELECT Row#
	,dateStartDetail
	,dateEndDetail
	,dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
	,dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
	,dateStartDetail AS time_endque
	,DATEADD(ss, cal_txfer, dateStartDetail) AS time_ring
	,DATEADD(ss, cal_txfer + cal_tring, dateStartDetail) AS time_dialog
	,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, dateStartDetail) AS time_notes
	,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, dateStartDetail) AS time_end_call
	,cal_Ani AS phone_in
	,cal_id
	,dni_id
	,Inbound_id
	,[User_id]
	,1 AS ntotal
	,CASE WHEN statuscall_id = 1 THEN 1 ELSE 0 END AS ninitial
	,CASE WHEN statuscall_id = 2 THEN 1 ELSE 0 END AS nout_hour
	,CASE WHEN statuscall_id = 3 THEN 1 ELSE 0 END AS nout_service
	,CASE WHEN statuscall_id IN (5, 6) AND cal_que > 0
			AND (cal_xfer is null or  cal_xfer = '1900-01-01 00:00:00') THEN 1 ELSE 0 END AS nabnd
	,CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
	,CASE WHEN cal_que > 0 THEN 1 ELSE 0 END AS nque
	,CASE WHEN statuscall_id = 7 THEN 1 ELSE 0 END AS ntimeout
	,CASE WHEN statuscall_id = 8 THEN 1 ELSE 0 END AS noverflow
	,CASE WHEN statuscall_id IN (11, 15, 13, 16)
			OR (
				statuscall_id = 6
				AND cal_xfer <> '1900-01-01 00:00:00'
				) THEN 1 ELSE 0 END AS nxfer
	,CASE WHEN cal_que > 0
			AND (
				statuscall_id IN (11, 15, 13, 16)
				OR (
					statuscall_id = 6
					AND cal_xfer <> '1900-01-01 00:00:00'
					)
				) THEN 1 ELSE 0 END AS nxfer_que
	,CASE WHEN (statuscall_id = 11)
			OR (
				statuscall_id = 6
				AND cal_xfer <> '1900-01-01 00:00:00'
				) THEN 1 ELSE 0 END AS nabnd_xfer
	,CASE WHEN (
				(statuscall_id = 15)
				AND (cal_tring <= @tresRing)
				) THEN 1 ELSE 0 END AS nabnd_ring
	,CASE WHEN (
				(statuscall_id = 15)
				AND (cal_tring > @tresRing)
				) THEN 1 ELSE 0 END AS nno_answer
	,CASE WHEN (
				(statuscall_id = 13)
				AND (cal_tdialog <= @tresDialog)
				) THEN 1 ELSE 0 END AS nabnd_dialog
	,CASE WHEN (
				(statuscall_id = 13)
				AND (cal_tdialog > @tresDialog)
				) THEN 1 ELSE 0 END AS nanswer
	,CASE WHEN (statuscall_id = 16) THEN 1 ELSE 0 END AS nlost
	,CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE 0 END AS nmsg
	,CASE WHEN (
				(
					statuscall_id IN (5, 6)
					AND cal_que > 0
					AND (cal_xfer is null or  cal_xfer = '1900-01-01 00:00:00')
					)
				AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)
				) THEN 1 ELSE 0 END AS nabnd_tres
	,CASE WHEN (
				(
					statuscall_id = 13
					AND cal_tdialog > @tresDialog
					)
				AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)
				) THEN 1 ELSE 0 END AS nansw_tres
	,cal_twait AS tque_max
	,cal_twait AS tque
	,cal_txfer AS txfer
	,cal_tdialog AS tdialog
	,cal_tnotas AS tnotes
	,cal_tring AS tring
	,CASE WHEN statuscall_id = 13
			AND cal_tdialog > @tresDialog THEN cal_twait + cal_txfer + cal_tring ELSE 0 END AS tresp
	,CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
	,CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
	,CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
	,statusCall_id
	,dateadd(ss, cal_twait + cal_txfer + cal_tring, cal_Inicio) AS [dateTResp]
	,dateadd(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_Inicio) AS [dateTACD]
	,calif_id
	,cal_tMoh
	,cal_puerto
FROM inboundData

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
			AND A.camType = 0
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
		,A.User_id = CASE WHEN A.User_id > 0 THEN B.userId ELSE A.User_id END
	FROM tmpTimesInboundData A
	INNER JOIN timeAcumlate B ON A.Inbound_id = B.camId
		AND A.cal_id = B.callId
END

SELECT *
INTO #inboundData2
FROM tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

DELETE tmpTimesInboundData
WHERE DATEDIFF(mi, timegroup, timegroup_next) > 15;

INSERT INTO tmpTimesInboundData
SELECT [row]
	,dateStartDetail
	,dateEndDetail
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,time_endque
	,time_ring
	,time_dialog
	,time_notes
	,time_end_call
	,phone_in
	,cal_id
	,dni_id
	,Inbound_id
	,[User_id]
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ntotal ELSE 0 END AS ntotal
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ninitial ELSE 0 END AS ninitial
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nout_hour ELSE 0 END AS nout_hour
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nout_service ELSE 0 END AS nout_service
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd ELSE 0 END AS nabnd
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nque ELSE 0 END AS nque
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN ntimeout ELSE 0 END AS ntimeout
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN noverflow ELSE 0 END AS noverflow
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nxfer ELSE 0 END AS nxfer
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nxfer_que ELSE 0 END AS nxfer_que
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
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nmsg ELSE 0 END AS nmsg
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nabnd_tres ELSE 0 END AS nabnd_tres
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nansw_tres ELSE 0 END AS nansw_tres
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN tque_max ELSE 0 END AS tque_max
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
	,dbo.TimeInterval(th.start, th.stop, time_endque, time_ring) AS txfer
	,dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
	,dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
	,dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
	,dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nMoh ELSE 0 END AS nMoh
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHag ELSE 0 END AS nWHag
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl
	,statusCall_id
	,[dateTResp]
	,[dateTACD]
	,CASE WHEN th.start > dateStartDetail
			AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id
	,dbo.AccountInterval(th.start ,th.stop , dateStartDetail,dateEndDetail,cal_tMoh) as cal_tMoh
	,cal_puerto
FROM #inboundData2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timegroup_next
WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
	AND th.Start BETWEEN @from
		AND @to
ORDER BY [row]
	,th.start

IF OBJECT_ID(N'tempdb..#outboundData2', N'U') IS NOT NULL
	DROP TABLE #outboundData2