/*
Autor: Armando Rodriguez
Fecha: 2011/04/29
Descripcion: Actualizacion de querys para tener reportes actualizados cada hora
Version requerida: 16
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '17'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAbndWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInAbndWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAbndWG (timegroup, idwg, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, idwg
		, COUNT(cal_inicio) AS amount
		, MAX(tAbnd) AS time_max
		, SUM(tAbnd) AS time_tot
		, COUNT(CASE WHEN tAbnd < 10  THEN 1 ELSE NULL END) as [<10]
		, COUNT(CASE WHEN tAbnd BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
		, COUNT(CASE WHEN tAbnd BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
		, COUNT(CASE WHEN tAbnd BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
		, COUNT(CASE WHEN tAbnd BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
		, COUNT(CASE WHEN tAbnd BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
		, COUNT(CASE WHEN tAbnd BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
		, COUNT(CASE WHEN tAbnd BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
		, COUNT(CASE WHEN tAbnd BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
		, COUNT(CASE WHEN tAbnd BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
		, COUNT(CASE WHEN tAbnd >= 300  THEN 1 ELSE NULL END) as [+300]
	 FROM	(
			SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
				, cal_inicio
				, wg.idwg
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 0
				AND wg.idwg > 0
		) xCalls
	WHERE (abnd IS NOT NULL) 
	 GROUP BY timegroup, idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAnswWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @tresDialog AS smallint

EXEC @tresDialog = ccspConfigTresDialog

DELETE ccGenInAnswWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAnswWG (timegroup, idwg, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, idwg
		, COUNT(cal_inicio) AS amount
		, MAX(tAnsw) AS time_max
		, SUM(tAnsw) AS time_tot
		, COUNT(CASE WHEN tAnsw < 10  THEN 1 ELSE NULL END) as [<10]
		, COUNT(CASE WHEN tAnsw BETWEEN 10 AND 19  THEN 1 ELSE NULL END) as [<20]
		, COUNT(CASE WHEN tAnsw BETWEEN 20 AND 29  THEN 1 ELSE NULL END) as [<30]
		, COUNT(CASE WHEN tAnsw BETWEEN 30 AND 39  THEN 1 ELSE NULL END) as [<40]
		, COUNT(CASE WHEN tAnsw BETWEEN 40 AND 49  THEN 1 ELSE NULL END) as [<50]
		, COUNT(CASE WHEN tAnsw BETWEEN 50 AND 59  THEN 1 ELSE NULL END) as [<60]
		, COUNT(CASE WHEN tAnsw BETWEEN 60 AND 119  THEN 1 ELSE NULL END) as [<120]
		, COUNT(CASE WHEN tAnsw BETWEEN 120 AND 179  THEN 1 ELSE NULL END) as [<180]
		, COUNT(CASE WHEN tAnsw BETWEEN 180 AND 239  THEN 1 ELSE NULL END) as [<240]
		, COUNT(CASE WHEN tAnsw BETWEEN 240 AND 299  THEN 1 ELSE NULL END) as [<300]
		, COUNT(CASE WHEN tAnsw >= 300  THEN 1 ELSE NULL END) as [+300]
	 FROM	(
			SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
				, cal_inicio
				, wg.idwg
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 0
				AND wg.idwg > 0
		) xCalls
	 WHERE (answer IS NOT NULL)
	 GROUP BY timegroup, idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, wg.idwg, calif_id, COUNT(cal_inicio)
 FROM ccCallsIN ci with(index(IX_ccCallsIn),nolock), ccRIAworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 and ci.cal_id = wg.cal_id and wg.tipo = 0
AND wg.idwg > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

DELETE FROM ccGenInCallWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCallWG (timegroup,idwg,ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
	, nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,idwg,ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
 FROM (SELECT xDetailTime.timegroup, xDetailTime.idwg
			, ISNULL(ntotal, 0) AS ntotal, ISNULL(initial, 0) AS ninitial, ISNULL(out_hour, 0) AS nout_hour, ISNULL(out_service, 0) AS nout_service
			, ISNULL(abnd, 0) AS nabnd, ISNULL(no_agent, 0) AS nno_agent, ISNULL(que, 0) AS nque, ISNULL(timeout, 0) AS ntimeout
			, ISNULL(overflow, 0) AS noverflow, ISNULL(xfer, 0) AS nxfer, ISNULL(xfer_que, 0) AS nxfer_que
			, ISNULL(abnd_xfer, 0) AS nabnd_xfer, ISNULL(abnd_ring, 0) AS nabnd_ring, ISNULL(no_answer, 0) AS nno_answer
			, ISNULL(abnd_dialog, 0) AS nabnd_dialog, ISNULL(answer, 0) AS nanswer, ISNULL(lost, 0) AS nlost, ISNULL(msg, 0) AS nmsg
			, ISNULL(abnd_tres, 0) AS nabnd_tres, ISNULL(answ_tres, 0) AS nansw_tres, ISNULL(tque_max, 0) AS tque_max
			, xDetailTime.tque, xDetailTime.txfer, xDetailTime.tring, xDetailTime.tdialog, xDetailTime.tnotes, ISNULL(tresp, 0) AS tresp,ISNULL(nMoh,0)AS nMoh
			,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM (SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup,wg.idwg
					, COUNT(ci.cal_id) AS ntotal
					, COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
					, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
					, COUNT(CASE WHEN(statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd 
					, COUNT(CASE WHEN(statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
					, COUNT(CASE WHEN(cal_que > 0) THEN 1 ELSE NULL END) AS que 
					, COUNT(CASE WHEN(statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
					, COUNT(CASE WHEN(statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
					, COUNT(CASE WHEN((statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS xfer
					, COUNT(CASE WHEN((cal_que > 0) and (statuscall_id in (11,15,13,16) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00''))) THEN cal_xfer ELSE NULL END) AS xfer_que
					, COUNT(CASE WHEN((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
					, COUNT(CASE WHEN((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
					, COUNT(CASE WHEN((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
					, COUNT(CASE WHEN((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
					, COUNT(CASE WHEN(statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
					, COUNT(CASE WHEN(statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
					, COUNT(CASE WHEN((statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = ''1900-01-01 00:00:00'') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
					, COUNT(CASE WHEN((statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS answ_tres
					, ISNULL(MAX(cal_twait), 0) AS tque_max,ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer,ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes,ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
					,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
					WHERE wg. cal_id = ci.cal_id and wg.tipo = 0 and cal_inicio >= @fromExtended AND  cal_inicio < @to AND wg.idwg > 0
				 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg
			) xDetailCount
			LEFT JOIN
			(
				SELECT timegroup
					, idwg
					, ISNULL(SUM(cal_twait), 0) AS tque
					, ISNULL(SUM(cal_txfer), 0) AS txfer
					, ISNULL(SUM(cal_tring), 0) AS tring
					, ISNULL(SUM(cal_tdialog), 0) AS tdialog
					, ISNULL(SUM(cal_tnotas), 0) AS tnotes
				 FROM (	SELECT timegroup, idwg
						, CASE WHEN time_endque < timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss, timegroup_next, time_endque) END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN cal_txfer WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN cal_txfer - DATEDIFF(ss, timegroup_next, time_ring) ELSE 0 END  AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN cal_tring WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN cal_tring - DATEDIFF(ss, timegroup_next, time_dialog) ELSE 0 END  AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN cal_tdialog WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN cal_tdialog - DATEDIFF(ss, timegroup_next, time_notes) ELSE 0 END  AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN cal_tnotas WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN cal_tnotas - DATEDIFF(ss, timegroup_next, time_end_call) ELSE 0 END  AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
								, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
								, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
								, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
								, ci.*, wg.idwg
							FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 0 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
						) xDetail
					UNION
					SELECT timegroup_next, idwg
						, CASE WHEN time_endque >= timegroup_next THEN DATEDIFF(ss, timegroup_next, time_endque) ELSE 0 END AS cal_twait
						, CASE WHEN (time_ring < timegroup_next) THEN 0 WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_ring) ELSE cal_txfer END AS cal_txfer
						, CASE WHEN (time_dialog < timegroup_next) THEN 0 WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_dialog) ELSE cal_tring END AS cal_tring
						, CASE WHEN (time_notes < timegroup_next) THEN 0 WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_notes) ELSE cal_tdialog END AS cal_tdialog
						, CASE WHEN (time_end_call < timegroup_next) THEN 0 WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN DATEDIFF(ss, timegroup_next, time_end_call) ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
								, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
								, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
								, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
								, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
								, ci.*, wg.idwg
							FROM ccCallsIn ci with(index(IX_ccCallsIn),nolock), ccRIAWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 0 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
						) xDetail
					) xTimeDetail
				 GROUP BY timegroup, idwg
			) xDetailTime
			ON (xDetailTime.timegroup = xDetailCount.timegroup AND xDetailTime.idwg = xDetailCount.idwg)
	) xComplete
 WHERE timegroup >= @from AND  timegroup < @to
	AND NOT (ntotal = 0 AND nout_hour = 0 AND nout_service = 0 AND nabnd = 0 AND nno_agent = 0 AND nque = 0
		 AND ntimeout = 0 AND noverflow = 0 AND nxfer = 0 AND nxfer_que = 0 AND nabnd_xfer = 0 AND nabnd_ring = 0
		 AND nno_answer = 0 AND nabnd_dialog = 0 AND nanswer = 0 AND nlost = 0 AND nmsg = 0 AND nabnd_tres = 0
		 AND nansw_tres = 0 AND tque_max = 0 AND tque = 0 AND txfer = 0 AND tring = 0 AND tdialog = 0 AND tnotes = 0 AND tresp = 0)
 ORDER BY timegroup, idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInSpecWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on
-- Delete previous data in case of reprocess HLAS
DELETE ccGenInSpecWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInSpecWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, wgs.idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max -- pos_tot
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, ci.inbound_id from ccRIAWorkGroup_Calid wg, cccallsin ci with(index(IX_ccCallsIn),nolock) where wg.cal_id = ci.cal_id and wg.tipo = 0 and wg.timestamp >= @from AND wg.timestamp < @to)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from AND timegroup < @to  AND wgs.idwg > 0
GROUP BY timegroup, wgs.idwg
return(0)
set nocount off
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup, wg.idwg, calif_id, COUNT(*)
 FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock), ccRIAworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to and co.cal_id = wg.cal_id and wg.tipo = 1
 AND statuscall_id = 13
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint
SELECT @HourExtend=2
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog

DELETE FROM ccGenOutCallWG WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenOutCallWG (timegroup,idwg,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl)
SELECT timegroup,idwg,ntotal,nno_agent,nxfer,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
 FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.idwg
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,wg.idwg
					,COUNT(co.cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN co.cal_id ELSE NULL END)AS hung_up --NO se usa,así que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN co.cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN co.cal_id ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN co.cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN co.cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN co.cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN co.cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN co.cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN co.cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock), ccRIAworkgroup_calid wg
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 1
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),wg.idwg
			)xDetailCount
			LEFT JOIN
			(SELECT timegroup
					, idwg
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,0 as idwg
						,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call								,*
							FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock)
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next, idwg
						,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
						,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
						,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
						,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
					 FROM	(
							SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
								,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
								,0 AS time_endque
								,DATEADD(ss,cal_txfer,cal_inicio) AS time_ring
								,DATEADD(ss,cal_txfer + cal_tring,cal_inicio) AS time_dialog
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
								,DATEADD(ss,cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
								,co.* , wg.idwg
							FROM ccoCallsOut co with(index(IX_ccoCallsOut_2),nolock), ccRIAworkgroup_calid wg
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 1
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup, idwg
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.idwg=xDetailCount.idwg)
	)xComplete
 WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
 ORDER BY timegroup,idwg
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCampWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on

declare @to2 as smalldatetime
declare @from2 as smalldatetime

SELECT @to2 = @to 
SELECT @from2 = @from

DELETE ccGenOutCampWG WHERE timegroup >= @from2 AND timegroup < @to2

INSERT INTO ccGenOutCampWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, co.cam_id from ccRIAWorkGroup_Calid wg, ccocallsout co with(index(IX_ccoCallsOut_2),nolock) where wg.cal_id = co.cal_id and wg.tipo = 1 and co.cal_inicio >= @from2 AND co.cal_inicio < @to2)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from2 AND timegroup < @to2
GROUP BY timegroup, idwg

return(0)
set nocount off
'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenTelMarcados'',
''declare @end as smalldatetime, @start as smalldatetime  
set @end = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121) 
set @start = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121) 
EXEC ccspGenTelMarcados @start, @end'',''*N/A*'',1,0,60,''01/01/1900 00:30'',''01/01/1900 02:45'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)
'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set starttime = ''01/01/1900 00:01:00'', endtime = ''01/01/1900 23:59:00'' where useCCenincnx = 1 and useCCrepindes = 1'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set Interval = 58, starttime = ''01/01/1900 00:10:00'', endtime = ''01/01/1900 23:59:00'' where description in(''ccspGenSession'',''ccspGenInCall'',''ccspGenInCallDNI'',''ccspGenOutCall'',''ccspGenAgentStatusSepHour'',''ccspGenAgentStatusSepHourNotReady'',''ccspGenOutCallWG'',''ccspGenInCallWG'')'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set Interval = 59, starttime = ''01/01/1900 00:20:00'', endtime = ''01/01/1900 23:59:00'' where description in(''ccspGenAgent'',''ccspGenAgentStatusNotReady'',''ccspGenInAbnd'',''ccspGenInAbndWG'',''ccspGenInAnsw'',''ccspGenInAnswWG'',''ccspGenOutCallCalif'',''ccGenOutCallCalifWG'',''ccspGenInCalif'',''ccspGenInCalifWG'')'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set Interval = 60, starttime = ''01/01/1900 00:30:00'', endtime = ''01/01/1900 23:59:00'' where description in(''ccspGenInSpec'',''ccspGenInSpecWG'',''ccspGenOutCamp'',''ccGenOutCampWG'',''ccspGenOutCallDials'',''ccGenOutCallDialsWG'',''ccspGenOutCstoResumen'',''ccspGenTelMarcados'')'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set useCCRepInDes = 1 where description in(''ccspGenSession'',''ccspGenInCall'',''ccspGenInCallDNI'',''ccspGenOutCall'',''ccspGenAgentStatusSepHour'',''ccspGenAgentStatusSepHourNotReady'',''ccspGenOutCallWG'',''ccspGenInCallWG'',''ccspGenAgent'',''ccspGenAgentStatusNotReady'',''ccspGenInAbnd'',''ccspGenInAbndWG'',''ccspGenInAnsw'',''ccspGenInAnswWG'',''ccspGenOutCallCalif'',''ccGenOutCallCalifWG'',''ccspGenInCalif'',''ccspGenInCalifWG'',''ccspGenInSpec'',''ccspGenInSpecWG'',''ccspGenOutCamp'',''ccGenOutCampWG'',''ccspGenOutCallDials'',''ccGenOutCallDialsWG'',''ccspGenOutCstoResumen'',''ccspGenTelMarcados'')'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime 
set @start = convert(smalldatetime,convert(varchar(11),getdate(),121) + ''''00:00:00'''',121) 
set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121) 
'' + rtrim(ltrim(substring(readquery,189,500))) where description in(''ccspGenSession'',''ccspGenAgentStatusSepHour'',''ccspGenAgentStatusSepHourNotReady'',''ccspGenAgent'',''ccspGenInSpec'',''ccspGenInSpecWG'',''ccspGenOutCamp'',''ccGenOutCampWG'')
'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set readquery = ''declare @end as smalldatetime, @start as smalldatetime 
set @start = dateadd(hh,-2,convert(smalldatetime,convert(varchar(14),getdate(),121) + ''''00:00'''',121)) 
set @end = convert(smalldatetime,convert(varchar(14),dateadd(hh,-1,getdate()),121) + ''''00:00'''',121) 
'' + rtrim(ltrim(substring(readquery,189,500))) where description in(''ccspGenInCall'',''ccspGenInCallDNI'',''ccspGenOutCall'',''ccspGenOutCallWG'',''ccspGenInCallWG'',''ccspGenAgentStatusNotReady'',''ccspGenInAbnd'',''ccspGenInAbndWG'',''ccspGenInAnsw'',''ccspGenInAnswWG'',''ccspGenOutCallCalif'',''ccGenOutCallCalifWG'',''ccspGenInCalif'',''ccspGenInCalifWG'',''ccspGenOutCallDials'',''ccGenOutCallDialsWG'',''ccspGenOutCstoResumen'')
'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set Interval = 11 where description in(''ccocallsout'',''cccallsin'',''cclogtransfers'')'
	EXEC(@Sql)

 	set @Sql='update exp_jobs set Interval = 9 where description in(''ccoLogDials'',''ccGenWorkGroup_Calid'',''ccGenWorkGroup_logdial_id'')'
	EXEC(@Sql)

 	set @Sql='alter table ccTipoCalif drop constraint PK_ccTipoCalif'
	EXEC(@Sql)

 	set @Sql='alter table ccTipoCalif alter column calif_id smallint NOT NULL'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccTipoCalif ADD CONSTRAINT
	PK_ccTipoCalif PRIMARY KEY CLUSTERED 
	(
	calif_id
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccRIAWorkGroup_Calid'',
''declare @end as smalldatetime, @start as smalldatetime
declare @sql  varchar(8000) 
declare @server varchar(200)

select @server = valor from ccsettings where setting_id = 22

set @end = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121) 
set @start = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121) 

set @sql = ''''declare @calIni as varchar(15)
declare @calfin as varchar(15)
select @calIni = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccRIAWorkGroup_Calid WITH(NOLOCK) where tipo = 0 and user_id = 0 
select @calfin = min(cal_id) from ( select isnull(min(cal_id),0) cal_id from ccRIAWorkGroup_Calid where timestamp > '''' + char(0x27) +  convert(varchar(20),@end,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccRIAWorkGroup_Calid WITH(NOLOCK)) as a where cal_id <> 0
''''
set @sql = @sql + ''''select IDWG, cal_id, user_id,cal_inicio as timestamp,''''''''0'''''''' as tipo from cccallsin ci left join ccRIACampEspWG cewg on (cewg.idcampesp = ci.inbound_id  and cewg.tipo = 0 ) where ci.user_id = 0 and ci.cal_id > @calIni and ci.cal_id < @calfin''''
--print @sql
exec (@sql)'',''ccRIAWorkGroup_Calid'',1,0,10,''01/01/1900 00:01'',''01/01/1900 23:59'',''1111111'','''','''','''','''','''','''',0,'''','''',1,1)
'
	EXEC(@Sql)

 	set @Sql='ALTER PROCEDURE [dbo].[A_cwRepNotReady]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(max)='''',
@CblDos as varchar(2000) = ''''

AS
declare @cursor as varchar (Max)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(max)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(max)
DECLARE @sql2 as varchar(max)
DECLARE @nodiponibles as varchar(max)
DECLARE @sumNoDip as varchar(max)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)
DECLARE @totalC as varchar(250)
DECLARE @totalT as varchar(250)

DECLARE @sSQL as varchar(max)
DECLARE @sSQL2 as varchar(max)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady
''
    end
    else
    begin
	set @cursor = @cursor +''select TipoNotReady_id, Descripcion from ccTipoNotReady where TipoNotReady_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.user_id, nr.timegroup,'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + '' dbo.fGetHHmmSS (Sesion) Sesion''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + '' sum(Sesion) Sesion ''+char(0x27) + ''
set @totalC = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @totalT = ''+char(0x27) + '', sum (0''+char(0x27) + ''
set @sql = @sql+ ''+char(0x27) + '' (select isnull(SUM(tlog),'' +char(0x27)+''+ char(0x27) + char(0x27) +'' +char(0x27)+'') from ccGenAgent where user_id = nr.user_id and timegroup =  nr.timegroup ) Sesion ''+char(0x27) + ''
set @sql2 =  ''+char(0x27) +char(0x27) + ''

Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
                set @totalC = @totalC + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto])'' +char(0x27) + ''
                set @totalT = @totalT + ''+char(0x27)+''+ sum([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo])'' +char(0x27) + ''
                set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], dbo.fGetHHmmSS ([''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
                set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
				if @id  < 35
				begin
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql = @sql+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			    else
			    begin
			    	set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amountReal,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Monto]''+char(0x27)+''
					set @sql2 = @sql2+''+char(0x27)+'', sum(case when tiponotready_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(time,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Tiempo]''+char(0x27)+''
			    end
			
			Fetch Next From CCampos
			Into  @id, @desc
		End
	End

--print @sql
--print @nodiponibles
--print @sumNoDip


CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''  timegroup,''
   set @sGroup = ''timegroup ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
--   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
 --  set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121), ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''

end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
   set @sGroupDetail = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121), ''
   set @sGroup = '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+char(0x27)+char(0x27)+ ''-01''+char(0x27)+char(0x27)+'', 121) ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' [user_id] in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and tiponotready_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' tiponotready_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + ''set @sSQL = ''+char(0x27)+''SELECT Login, timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente, ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT ''+ @sGroup +'' as timegroup , [user_id], ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL2 = @sql2+  ''+char(0x27)+'' FROM ccGenAgentNotReady as nr WHERE timegroup >= ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @fini +char(0x27)+ '' + char(0x27) + ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27) + '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) 
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY  nr.timegroup, [user_id] ) as a WHERE timegroup >= ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @fini +char(0x27)+ ''+ char(0x27)+ ''+char(0x27)+'' AND timegroup < ''+char(0x27)+'' + char(0x27)+ '' +char(0x27)+ @ffin +char(0x27)+ '' + char(0x27) + ''+char(0x27)+''''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '' [user_id]  ) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' INNER JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) AND ccUsers.filter = 1 ORDER BY Fecha, Agente ''+char(0x27)+''

exec ( @sSQL + @sSQL2)
--print (@sSQL)
--print (@sSQL2)
''
if @idioma = 1
begin
set @cursor = replace(@cursor, ''Sesion'', ''Session'')
set @cursor = replace(@cursor, ''_Monto'', ''_Count'')
set @cursor = replace(@cursor, ''_Tiempo'', ''_Time'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

--print (@cursor)
exec (@cursor)
'
	EXEC(@Sql)

 	

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC]
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off


