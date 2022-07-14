CREATE PROCEDURE [dbo].[ccspRepInEffectiveness] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
SET NOCOUNT ON
SET ANSI_NULLS OFF
SET ANSI_WARNINGS OFF

IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()


IF @action = 1
BEGIN
	--Consulta de agentes conectados agrupados por hora e inboundid
	CREATE TABLE [dbo].[#ccGenSession] ([user_id] [smallint] NOT NULL, fechaInicio [datetime] NOT NULL, [tlog] INT NOT NULL) ON [PRIMARY]

	CREATE TABLE #AgentsperInbound (NumberAgents INT, fechaInicio DATETIME, fechaFinal DATETIME, Inbound_id INT)

	INSERT INTO [#ccGenSession]
	SELECT A.user_id, convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121) AS fechaInicio, sum(tlog) tlog
	FROM TmpSessionTimeGroup A
	GROUP BY A.user_id, convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121);

	WITH RtnValue3
	AS (
		SELECT DISTINCT 1 AS cont, A.user_id, B.Inbound_id, A.fechaInicio, DATEADD(hh, 1, A.fechaInicio) AS fechaFinal
		FROM [#ccGenSession] A
		INNER JOIN ccinboundagentes B
			ON A.user_id = B.User_id
		)
	INSERT INTO #AgentsperInbound
	SELECT sum(cont) AS NumberAgents, fechaInicio, fechaFinal, Inbound_id
	FROM RtnValue3
	GROUP BY fechaInicio, fechaFinal, Inbound_id

	--Fin consulta agentes conectados por inbound
	CREATE TABLE [dbo].[#ccGenInCall] (
		[timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [dni_id] [smallint] NOT NULL, [user_id] [smallint] NOT NULL, [ntotal] [smallint] NOT NULL, [nabnd] [smallint] NOT NULL, [nno_agent] [smallint] NOT 
		NULL, [nque] [smallint] NOT NULL, [ntimeout] [smallint] NOT NULL, [noverflow] [smallint] NOT NULL, [nno_answer] [smallint] NOT NULL, [nanswer] [smallint] NOT NULL, [nlost] [smallint] NOT NULL, [nabnd_tres] [smallint] 
		NOT NULL, [nansw_tres] [smallint] NOT NULL, [tque_max] [smallint] NOT NULL, [tque] [int] NOT NULL, [txfer] [int] NOT NULL, [tdialog] [int] NOT NULL, [tnotes] [int] NOT NULL, [tring] [int] NOT NULL, [tresp] [int] NOT NULL, 
		[nMoh] [smallint] NOT NULL DEFAULT((0)), [nWHag] [smallint] NOT NULL DEFAULT((0)), [nWHcl] [smallint] NOT NULL DEFAULT((0))
		) ON [PRIMARY]

	CREATE TABLE [dbo].[#agents] (
		[timegroup] [smalldatetime] NOT NULL, [user_id] [smallint] NOT NULL, [tlog] [int] NOT NULL DEFAULT(0), [treq] [int] NOT NULL DEFAULT(0), [tnot_av] [int] NOT NULL, [tav] [int] NOT NULL DEFAULT(0), [tprob] [int] NOT NULL 
		DEFAULT(0), [tunknown] [int] NOT NULL DEFAULT(0), [tother] [int] NOT NULL DEFAULT(0), [nother] [int] NOT NULL DEFAULT(0), [nMoh] [int] NOT NULL DEFAULT((0)), [nWHag] [int] NOT NULL DEFAULT((0
				)), [nWHcl] [int] NOT NULL DEFAULT((0))
		) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInSpec] ([timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [pos_tot] [smallint] NOT NULL, [pos_time] [int] NOT NULL, [pos_efect] [smallint] NOT NULL) ON [PRIMARY]

	CREATE TABLE [dbo].[#ccGenInAbnd] (
		[timegroup] [smalldatetime] NOT NULL, [inbound_id] [smallint] NOT NULL, [amount] [smallint] NOT NULL, [time_max] [smallint] NOT NULL, [time_tot] [bigint] NOT NULL, [<10] [smallint] NOT NULL, [<20] [smallint] NOT NULL, 
		[<30] [smallint] NOT NULL, [<40] [smallint] NOT NULL, [<50] [smallint] NOT NULL, [<60] [smallint] NOT NULL, [<120] [smallint] NOT NULL, [<180] [smallint] NOT NULL, [<240] [smallint] NOT NULL, [<300] [smallint] NOT NULL, 
		[+300] [smallint] NOT NULL
		) ON [PRIMARY]

	INSERT INTO #ccGenInCall (
		timegroup, inbound_id, dni_id, [user_id], ntotal, nabnd, nno_agent, nque, ntimeout, noverflow, nno_answer, nanswer, nlost, nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, tnotes, tresp, nMoh, nWHag, 
		nWHcl
		)
	SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121) AS timegroup, Inbound_id, dni_id, User_id, isnull(sum(ntotal), 0) AS ntotal, isnull(sum(nabnd), 0) AS nabnd, isnull(sum(nno_agent), 0) AS 
		nno_agent, isnull(sum(nque), 0) AS nque, isnull(sum(ntimeout), 0) AS ntimeout, isnull(sum(noverflow), 0) AS noverflow, isnull(sum(nno_answer), 0) AS nno_answer, isnull(sum(nanswer), 0) AS nanswer, isnull(sum(nlost
			), 0) AS nlost, isnull(sum(nabnd_tres), 0) AS nabnd_tres, isnull(sum(nansw_tres), 0) AS nansw_tres, isnull(max(tque_max), 0) AS tque_max, isnull(sum(tque), 0) AS tque, isnull(sum(txfer), 0) AS txfer, isnull(sum(
				tdialog), 0) AS tdialog, isnull(sum(tnotes), 0) AS tnotes, isnull(sum(tring), 0) AS tring, isnull(sum(tresp), 0) AS tresp, isnull(sum(nMoh), 0) AS nMoh, isnull(sum(nWHag), 0) AS nWHag, isnull(sum(nWHcl), 0) AS 
		nWHcl
	FROM tmpTimesInboundData
	GROUP BY convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121), inbound_id, dni_id, [user_id];

	WITH timeAgent
	AS (
		SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121) timegroup, userId, ISNULL(SUM(CASE WHEN (tipostatusage_id = 2) THEN tStatus ELSE NULL END), 0) AS 
			tnot_av, ISNULL(SUM(CASE WHEN (tipostatusage_id = 3) THEN tStatus ELSE NULL END), 0) AS tav, ISNULL(SUM(CASE WHEN (tipostatusage_id = 11) THEN 
								tStatus ELSE NULL END), 0) AS tprob, ISNULL(SUM(CASE WHEN (tipostatusage_id = 1) THEN tStatus ELSE NULL END), 0) AS tunknown, ISNULL(SUM(CASE WHEN (tipostatusage_id = 7
								) THEN tStatus ELSE NULL END), 0) AS tother, COUNT(CASE WHEN (tipostatusage_id = 7) THEN 1 ELSE NULL END) AS nother
		FROM tmpccLogAgentesDia
		GROUP BY convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121), userId
		)
	INSERT INTO #agents (timegroup, [user_id], tlog, tnot_av, tav, tprob, tunknown, tother, nother, nMoh, nWHag, nWHcl)
	SELECT A.fechaInicio AS timegroup, A.user_id, A.tlog, isnull(B.tnot_av, 0) AS tnot_av, isnull(B.tav, 0) AS tav, isnull(B.tprob, 0) AS tprob, isnull(B.tunknown, 0) AS tunknown, isnull(B.tother, 0) AS tother, isnull(B.nother
			, 0) AS nother, isnull(ci.nMoh, 0) AS nMoh, isnull(ci.nWHag, 0) AS nWHag, isnull(ci.nWHcl, 0) AS nWHcl
	FROM [#ccGenSession] A
	LEFT JOIN timeAgent B
		ON A.user_id = B.userId
			AND A.fechaInicio = B.timegroup
	LEFT JOIN #ccGenInCall ci
		ON A.user_id = ci.user_id
			AND A.fechaInicio = ci.timegroup

	INSERT INTO #ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
	SELECT timegroup, ccInboundAgentes.inbound_id, 
	COUNT(DISTINCT #agents.[user_id]) AS pos_max, 
	SUM(tlog - (tnot_av + tprob + tother)) AS pos_time, 
	COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	FROM #agents
	INNER JOIN ccInboundAgentes
		ON (#agents.[user_id] = ccInboundAgentes.[user_id])
	WHERE timegroup >= @from
		AND timegroup < @to
		AND INBOUND_ID > 0
	GROUP BY timegroup, ccInboundAgentes.inbound_id		
		;

	WITH callInAbnd
	AS (
		SELECT convert(DATETIME, convert(VARCHAR(14), timegroup, 121) + '00:00', 121) AS timegroup, inbound_id, tque + txfer + tring AS tAbnd, nabnd, CASE WHEN statuscall_id IN (5, 6)
					AND nabnd > 0 THEN 1 ELSE 0 END nabnd2
		FROM tmpTimesInboundData
		WHERE statuscall_id IN (5, 6)
		)
	INSERT INTO #ccGenInAbnd
	SELECT timegroup, inbound_id, sum(nabnd2) amount, max(tAbnd) time_max, sum(tAbnd) AS time_tot, COUNT(CASE WHEN tAbnd < 10 THEN 1 ELSE NULL END) AS [<10], COUNT(CASE WHEN tAbnd BETWEEN 10
						AND 19 THEN 1 ELSE NULL END) AS [<20], COUNT(CASE WHEN tAbnd BETWEEN 20
						AND 29 THEN 1 ELSE NULL END) AS [<30], COUNT(CASE WHEN tAbnd BETWEEN 30
						AND 39 THEN 1 ELSE NULL END) AS [<40], COUNT(CASE WHEN tAbnd BETWEEN 40
						AND 49 THEN 1 ELSE NULL END) AS [<50], COUNT(CASE WHEN tAbnd BETWEEN 50
						AND 59 THEN 1 ELSE NULL END) AS [<60], COUNT(CASE WHEN tAbnd BETWEEN 60
						AND 119 THEN 1 ELSE NULL END) AS [<120], COUNT(CASE WHEN tAbnd BETWEEN 120
						AND 179 THEN 1 ELSE NULL END) AS [<180], COUNT(CASE WHEN tAbnd BETWEEN 180
						AND 239 THEN 1 ELSE NULL END) AS [<240], COUNT(CASE WHEN tAbnd BETWEEN 240
						AND 299 THEN 1 ELSE NULL END) AS [<300], COUNT(CASE WHEN tAbnd >= 300 THEN 1 ELSE NULL END) AS [+300]
	FROM callInAbnd
	GROUP BY timegroup, inbound_id

	--Borrar lo que esta para no repetir  
	DELETE	FROM RepInEffectiveness 	WHERE DATE >= @from		AND DATE < @to
	
	;with xDetCall as(
	SELECT timegroup, inbound_id, SUM(ntotal) AS ntotal, SUM(nanswer) AS nanswer, SUM(nabnd) AS nabnd, SUM(tdialog + tnotes) tatention, ISNULL(sum(tque) / NULLIF(sum(nque), 0), 0) AS tque_avg, sum(tque) AS tQue_tot, sum(nQue) 
		AS nQue_tot, SUM(nansw_tres + nabnd_tres) AS SL_P_1, SUM(nanswer + nabnd + nno_agent + ntimeout + noverflow + nno_answer + nlost) AS SL_P_2, SUM(tresp) AS tresp
	FROM #ccGenInCall
	WHERE timegroup >= @from
		AND timegroup < @to
	GROUP BY timegroup, inbound_id
	),xDetSpec as(
	SELECT timegroup, inbound_id, SUM(pos_tot) AS pos_tot, SUM(pos_tot) AS pos_avg, SUM(pos_efect) AS pos_efect
			FROM #ccGenInSpec
			WHERE timegroup >= @from
				AND timegroup < @to
			GROUP BY timegroup, inbound_id
	),xDetAbnd as (
	SELECT timegroup, inbound_id, SUM(time_tot) AS tabnd_tot
			FROM #ccGenInAbnd
			WHERE timegroup >= @from
				AND timegroup < @to
			GROUP BY timegroup, inbound_id
	),xDetail as(
	SELECT ISNULL(xDetCall.timegroup, ISNULL(xDetSpec.timegroup, xDetAbnd.timegroup)) timegroup, ISNULL(xDetCall.inbound_id, ISNULL(xDetSpec.inbound_id, xDetAbnd.inbound_id)) inbound_id, ISNULL(ntotal, 0) 
			ntotal, ISNULL(nanswer, 0) nanswer, ISNULL(nabnd, 0) nabnd, ISNULL(tatention, 0) tatention, ISNULL(tque_avg, 0) tque_avg, isnull(tQue_tot, 0) tQue_tot, isnull(nQue_tot, 0) nQue_tot, ISNULL(tabnd_tot, 0) 
			tabnd_tot, ISNULL(SL_P_1, 0) SL_P_1, ISNULL(SL_P_2, 0) SL_P_2, ISNULL(tresp, 0) tresp, ISNULL(pos_tot, 0) pos_tot
		FROM  xDetCall
		LEFT JOIN xDetSpec
			ON 
					xDetCall.timegroup = xDetSpec.timegroup
					AND xDetCall.inbound_id = xDetSpec.inbound_id
					
		LEFT JOIN  xDetAbnd
			ON 
					xDetCall.timegroup = xDetAbnd.timegroup
					AND xDetCall.inbound_id = xDetAbnd.inbound_id
	)
	----------
	INSERT INTO RepInEffectiveness
	SELECT timegroup AS DATE, xDetail.inbound_id, isnull(descripcion, 'systemTranslated_NoACDGroup') descripcion, ntotal, nanswer, nabnd, 
	isnull(tatention / nullif(nanswer, 0), 0) as tatencion, tque_avg AS tqueavg, tQue_tot AS tQuetot
		, nQue_tot AS nQuetot, isnull(tabnd_tot / NULLIF(nabnd, 0), 0) AS avgAbandonTime, SL_P_1 AS SLP1, SL_P_2 AS SLP2, tresp,
		isnull(c.NumberAgents,0) AS NumberAgents, ISNULL(SL_P_1 * 100 / NULLIF(SL_P_2, 0), 0) AS Porcentaje
		, datepart(yyyy, timegroup) AS [year]
		, datepart(mm, timegroup) AS [month]
		, datepart(dd, timegroup) AS [day]
		, datepart(hh, timegroup) AS [hour]
		, 0 AS [minutes]
		, convert(DECIMAL(10, 2), (nabnd / nullif(convert(DECIMAL(10, 2), ntotal), 0)) * 100) AS [avgAbandon]
		, tabnd_tot AS tabndtot
	FROM xDetail
	LEFT JOIN ccInbound ON xDetail.inbound_id = ccInbound.inbound_id
	left join #AgentsperInbound C on xDetail.inbound_id=C.Inbound_id and xDetail.timegroup=C.fechaInicio
	ORDER BY DATE

	
	DROP TABLE #ccGenInCall

	DROP TABLE #ccGenInSpec

	DROP TABLE #ccGenSession

	DROP TABLE #agents

	DROP TABLE #ccGenInAbnd

	DROP TABLE #AgentsperInbound
END