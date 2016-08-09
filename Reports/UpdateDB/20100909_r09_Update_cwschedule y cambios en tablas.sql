/*
Autor: Armando Rodriguez
Fecha: 2010/09/09
Descripcion: Actualizacion de querys para evitar insertar dos veces los datos y cambios en las tablas para controlar el manejo de los wg en los reportes, se agregan tablas, sp y jobs para la informacion de los reportes por workgroup
Version requerida: 8
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '9'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='ALTER TABLE ccSupervisorCam add IDWG int NOT NULL CONSTRAINT DF_ccSupervisorCam_IDWG DEFAULT 0'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE ccCampsAgente add IDWG int NOT NULL CONSTRAINT DF_ccCampsAgente_IDWG DEFAULT 0'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE ccInboundAgentes add IDWG int NOT NULL CONSTRAINT DF_ccInboundAgentes_IDWG DEFAULT 0'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccSupervisorCam DROP CONSTRAINT PK_ccSupervisorCam'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE dbo.ccSupervisorCam ADD CONSTRAINT PK_ccSupervisorCam PRIMARY KEY CLUSTERED  (user_id, cam_id, tipo, IDWG) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenWorkGroup_Calid](
	[IDWG] [smallint] NOT NULL,
	[cal_id] [int] NULL,
	[User_id] [int] NOT NULL,
	[timestamp] [datetime] NOT NULL,
	[tipo] [int] NOT NULL
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX IX_WGCal_id ON dbo.ccGenWorkGroup_Calid (IDWG)'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccGenWorkGroup_logdial_id](
	[IDWG] [smallint] NOT NULL,
	[logdial_id] [int] NULL,
	[CAM_ID] [smallint] NOT NULL,
	[timestamp] [datetime] NOT NULL
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX IX_WGlogDial_id ON dbo.ccGenWorkGroup_logDial_id (IDWG)'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenInCallWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[ntotal] [smallint] NOT NULL,
	[ninitial] [smallint] NOT NULL,
	[nout_hour] [smallint] NOT NULL,
	[nout_service] [smallint] NOT NULL,
	[nabnd] [smallint] NOT NULL,
	[nno_agent] [smallint] NOT NULL,
	[nque] [smallint] NOT NULL,
	[ntimeout] [smallint] NOT NULL,
	[noverflow] [smallint] NOT NULL,
	[nxfer] [smallint] NOT NULL,
	[nxfer_que] [smallint] NOT NULL,
	[nabnd_xfer] [smallint] NOT NULL,
	[nabnd_ring] [smallint] NOT NULL,
	[nno_answer] [smallint] NOT NULL,
	[nabnd_dialog] [smallint] NOT NULL,
	[nanswer] [smallint] NOT NULL,
	[nlost] [smallint] NOT NULL,
	[nmsg] [smallint] NOT NULL,
	[nabnd_tres] [smallint] NOT NULL,
	[nansw_tres] [smallint] NOT NULL,
	[tque_max] [smallint] NOT NULL,
	[tque] [int] NOT NULL,
	[txfer] [int] NOT NULL,
	[tdialog] [int] NOT NULL,
	[tnotes] [int] NOT NULL,
	[tring] [int] NOT NULL,
	[tresp] [int] NOT NULL,
	[nMoh] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCallWG_tMoh]  DEFAULT ((0)),
	[nWHag] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCallWG_nWHag]  DEFAULT ((0)),
	[nWHcl] [smallint] NOT NULL CONSTRAINT [DF_ccGenInCallWG_nWHcl]  DEFAULT ((0)),
 CONSTRAINT [PK_ccGenInCallWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenInSpecWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[pos_tot] [smallint] NOT NULL,
	[pos_time] [int] NOT NULL,
	[pos_efect] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenInSpecWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenInAbndWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[amount] [smallint] NOT NULL,
	[time_max] [smallint] NOT NULL,
	[time_tot] [bigint] NOT NULL,
	[<10] [smallint] NOT NULL,
	[<20] [smallint] NOT NULL,
	[<30] [smallint] NOT NULL,
	[<40] [smallint] NOT NULL,
	[<50] [smallint] NOT NULL,
	[<60] [smallint] NOT NULL,
	[<120] [smallint] NOT NULL,
	[<180] [smallint] NOT NULL,
	[<240] [smallint] NOT NULL,
	[<300] [smallint] NOT NULL,
	[+300] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenInAbndWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenInAnswWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[amount] [smallint] NOT NULL,
	[time_max] [smallint] NOT NULL,
	[time_tot] [bigint] NOT NULL,
	[<10] [smallint] NOT NULL,
	[<20] [smallint] NOT NULL,
	[<30] [smallint] NOT NULL,
	[<40] [smallint] NOT NULL,
	[<50] [smallint] NOT NULL,
	[<60] [smallint] NOT NULL,
	[<120] [smallint] NOT NULL,
	[<180] [smallint] NOT NULL,
	[<240] [smallint] NOT NULL,
	[<300] [smallint] NOT NULL,
	[+300] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenInAnswWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenInCalifWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[calif_id] [tinyint] NOT NULL,
	[amount] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenInCalifWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC,
	[calif_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenOutCallWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[ntotal] [smallint] NOT NULL,
	[nno_agent] [smallint] NOT NULL,
	[nxfer] [smallint] NOT NULL,
	[nabnd_xfer] [smallint] NOT NULL,
	[nabnd_ring] [smallint] NOT NULL,
	[nno_answer] [smallint] NOT NULL,
	[nabnd_dialog] [smallint] NOT NULL,
	[nanswer] [smallint] NOT NULL,
	[nlost] [smallint] NOT NULL,
	[nhangup] [smallint] NULL,
	[txfer] [int] NOT NULL,
	[tdialog] [int] NOT NULL,
	[tnotes] [int] NOT NULL,
	[tring] [int] NOT NULL,
	[tresp] [int] NOT NULL,
	[nMoh] [int] NOT NULL CONSTRAINT [DF_ccGenOutCallWG_tMoh]  DEFAULT ((0)),
	[nWHag] [smallint] NOT NULL CONSTRAINT [DF_ccGenOutCallWG_nWHag]  DEFAULT ((0)),
	[nWHcl] [smallint] NOT NULL CONSTRAINT [DF_ccGenOutCallWG_nWHcl]  DEFAULT ((0)),
 CONSTRAINT [PK_ccGenOutCallWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenOutCampWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[pos_tot] [smallint] NOT NULL,
	[pos_time] [int] NOT NULL,
	[pos_efect] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenOutCampWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenOutCallCalifWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[calif_id] [smallint] NOT NULL,
	[amount] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenOutCallCalifWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC,
	[calif_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccGenOutCallDialsWG](
	[timegroup] [smalldatetime] NOT NULL,
	[idwg] [smallint] NOT NULL,
	[puerto] [smallint] NOT NULL,
	[tiporesdial_id] [smallint] NOT NULL,
	[amount] [smallint] NOT NULL,
 CONSTRAINT [PK_ccGenOutCallDialsWG] PRIMARY KEY CLUSTERED 
(
	[timegroup] ASC,
	[idwg] ASC,
	[puerto] ASC,
	[tiporesdial_id] ASC
) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [WorkGroup] ON [dbo].[ccGenOutCallDialsWG] 
(
	[idwg] ASC
)WITH FILLFACTOR = 80 ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [tipoMarcacion] ON [dbo].[ccGenOutCallDialsWG] 
(
	[tiporesdial_id] ASC
)WITH FILLFACTOR = 80 ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='Create PROCEDURE [dbo].[ccspGenInCallWG]
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
				 FROM ccCallsIn ci, ccGenWorkGroup_Calid wg
					WHERE wg. cal_id = ci.cal_id and wg.tipo = 1 and cal_inicio >= @fromExtended AND  cal_inicio < @to AND wg.idwg > 0
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
							FROM ccCallsIn ci, ccGenWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 1 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
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
							FROM ccCallsIn ci, ccGenWorkGroup_Calid wg
							WHERE wg.cal_id = ci.cal_id and wg.tipo = 1 and cal_inicio >= @fromExtended AND  cal_inicio < @to  AND wg.idwg > 0
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

	set @Sql='Create PROCEDURE [dbo].[ccspGenInSpecWG]
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
	(select distinct wg.user_id, wg.idwg, ci.inbound_id from ccGenWorkGroup_Calid wg, cccallsin ci where wg.cal_id = ci.cal_id and wg.tipo = 1 and wg.timestamp >= @from AND wg.timestamp < @to)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from AND timegroup < @to  AND wgs.idwg > 0
GROUP BY timegroup, wgs.idwg
return(0)
set nocount off'
	EXEC(@Sql)

	set @Sql='Create PROCEDURE [dbo].[ccspGenInAbndWG]
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
			 FROM ccCallsIn ci, ccGenWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 1
				AND wg.idwg > 0
		) xCalls
	WHERE (abnd IS NOT NULL) 
	 GROUP BY timegroup, idwg'
	EXEC(@Sql)

	set @Sql='Create PROCEDURE [dbo].[ccspGenInAnswWG]
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
			 FROM ccCallsIn ci, ccGenWorkGroup_Calid wg
				WHERE cal_inicio >= @from AND  cal_inicio < @to and wg.cal_id = ci.cal_id and wg.tipo = 1
				AND wg.idwg > 0
		) xCalls
	 WHERE (answer IS NOT NULL)
	 GROUP BY timegroup, idwg
'
	EXEC(@Sql)

	set @Sql='Create PROCEDURE [dbo].[ccspGenInCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenInCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, wg.idwg, calif_id, COUNT(cal_inicio)
 FROM ccCallsIN ci, ccgenworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 and ci.cal_id = wg.cal_id and wg.tipo = 1
AND wg.idwg > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

	set @Sql='Create PROCEDURE [dbo].[ccspGenOutCallWG]
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
				 FROM ccoCallsOut co, ccgenworkgroup_calid wg
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 0
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
							FROM ccoCallsOut co
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
							FROM ccoCallsOut co, ccgenworkgroup_calid wg
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to and co.cal_id = wg.cal_id and wg.tipo = 0
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

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCampWG]
@from AS smalldatetime,
@to AS smalldatetime
AS
set nocount on

DELETE ccGenOutCampWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCampWG (timegroup, idwg, pos_tot, pos_time, pos_efect)
SELECT timegroup, idwg
	, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
	, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
	, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
FROM ccGenAgent INNER JOIN 
	(select distinct wg.user_id, wg.idwg, co.cam_id from ccGenWorkGroup_Calid wg, ccocallsout co where wg.cal_id = co.cal_id and wg.tipo = 0 and co.cal_inicio >= @from AND co.cal_inicio < @to)as wgs 
	ON (ccGenAgent.[user_id] = wgs.[user_id])
WHERE timegroup >= @from AND timegroup < @to
GROUP BY timegroup, idwg

return(0)
set nocount off'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCallCalifWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallCalifWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallCalifWG (timegroup, idwg, calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup, wg.idwg, calif_id, COUNT(*)
 FROM ccoCallsOut co, ccgenworkgroup_calid wg
 WHERE cal_inicio >= @from AND  cal_inicio < @to and co.cal_id = wg.cal_id and wg.tipo = 0
 AND statuscall_id = 13
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), wg.idwg, calif_id
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenSession]
@from as smalldatetime,
@to as smalldatetime
AS
set nocount on
declare @to2 as smalldatetime
declare @from2 as smalldatetime

SELECT @to2 = @to --CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''00:00'', 121)
SELECT @from2 = @from -- DATEADD(d, -1, @to2)

delete  from ccGenSession where login >= @from2 and login<@to2
INSERT INTO ccGenSession ([user_id], extension, login, logout)
SELECT uid, max(ext) ext, login, max(logout) logout
FROM 
	(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(IX_ccLogLogin_2))
	WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
	FROM
		(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
		FROM 
			(SELECT uid, ext, MAX(login) as login, logout
			FROM
				(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
				FROM ccLogLogin subLogin with (nolock, index(IX_ccLogLogin_2)) WHERE subLogin.tipomov = 0 
				AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
				FROM ccLogLogin Login with (nolock, index(IX_ccLogLogin_2))
				WHERE login.fecha >= dateadd(dd, -5, @from2) and tipomov = 1
				GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
			WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
		RIGHT OUTER JOIN ccLogLogin  with (nolock, index(IX_ccLogLogin_2))
		ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
		WHERE tipomov = 1
		and ccLogLogin.fecha >= dateadd( dd, -5, @from2)) Det 
	) LoginDetail 
WHERE logout IS NOT NULL
AND login >= @from2 and login < @to2
GROUP BY uid, login

return(0)
set nocount off'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenOutCall]
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

DELETE FROM ccGenOutCall WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenOutCall(timegroup,cam_id,[user_id]
	,ntotal,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl)
SELECT timegroup,cam_id,[user_id],ntotal
	,nno_agent,nxfer
	,nabnd_xfer,nabnd_ring,nno_answer
	,nabnd_dialog,nanswer,nlost
	,txfer,tring,tdialog,tnotes,tresp,nhangup,nMoh,nWHag,nWHcl
 FROM(		
		SELECT xDetailTime.timegroup,xDetailTime.cam_id,xDetailTime.[user_id]
			,ISNULL(ntotal,0)AS ntotal
			,ISNULL(no_agent,0)AS nno_agent,ISNULL(xfer,0)AS nxfer
			,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
			,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost
			,xDetailTime.txfer,xDetailTime.tring
			,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp
			,ISNULL(hung_up,0)AS nhangup,ISNULL(nMoh,0) as nMoh,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
		 FROM(	 
				SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
					,cam_id
					,[user_id]
					,COUNT(cal_id)AS ntotal
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --Ne se usa,as que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					--,COUNT(CASE WHEN(statuscall_id in(11,15,13,16))THEN 1 ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
			--RIGHT OUTER JOIN 
			LEFT JOIN
			(
				SELECT timegroup
					,cam_id
					,[user_id]
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(cal_tring),0)AS tring
					,ISNULL(SUM(cal_tdialog),0)AS tdialog
					,ISNULL(SUM(cal_tnotas),0)AS tnotes
				 FROM(	SELECT timegroup,cam_id,[user_id]
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
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					UNION
					SELECT timegroup_next,cam_id,[user_id]
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
								,*
							FROM ccoCallsOut with (nolock, index(IX_ccoCallsOut_2))
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
							-- para contar bien las llamadas manuales
							and cal_manual in(0,2)
						)xDetail
					)xTimeDetail
				 GROUP BY timegroup,cam_id,[user_id]
			)xDetailTime
			ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.cam_id=xDetailCount.cam_id AND xDetailTime.[user_id]=xDetailCount.[user_id])
	)xComplete
 WHERE timegroup>=@from AND timegroup<@to
	AND NOT(ntotal=0 AND nno_agent=0
		 AND nxfer=0 AND nabnd_xfer=0 AND nabnd_ring=0
		 AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0
		 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)

 ORDER BY timegroup,cam_id,[user_id]'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCall]
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

DELETE FROM ccGenInCall WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenInCall(timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque
,ntimeout,noverflow,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg
,nabnd_tres,nansw_tres,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl)
SELECT timegroup,inbound_id,[user_id],ntotal,nout_hour,nout_service,nabnd,nno_agent,nque,ntimeout,noverflow
,nxfer,nxfer_que,nabnd_xfer,nabnd_ring,nno_answer,nabnd_dialog,nanswer,nlost,nmsg,nabnd_tres,nansw_tres
,tque_max,tque,txfer,tring,tdialog,tnotes,tresp,ninitial,nMoh,nWHag,nWHcl
FROM(SELECT xDetailTime.timegroup,xDetailTime.inbound_id,xDetailTime.[user_id],ISNULL(ntotal,0)AS ntotal,ISNULL(initial,0)AS ninitial
	,ISNULL(out_hour,0)AS nout_hour,ISNULL(out_service,0)AS nout_service,ISNULL(abnd,0)AS nabnd,ISNULL(no_agent,0)AS nno_agent
	,ISNULL(que,0)AS nque,ISNULL(timeout,0)AS ntimeout,ISNULL(overflow,0)AS noverflow,ISNULL(xfer,0)AS nxfer
	,ISNULL(xfer_que,0)AS nxfer_que,ISNULL(abnd_xfer,0)AS nabnd_xfer,ISNULL(abnd_ring,0)AS nabnd_ring,ISNULL(no_answer,0)AS nno_answer
	,ISNULL(abnd_dialog,0)AS nabnd_dialog,ISNULL(answer,0)AS nanswer,ISNULL(lost,0)AS nlost,ISNULL(msg,0)AS nmsg
	,ISNULL(abnd_tres,0)AS nabnd_tres,ISNULL(answ_tres,0)AS nansw_tres,ISNULL(tque_max,0)AS tque_max,xDetailTime.tque
	,xDetailTime.txfer,xDetailTime.tring,xDetailTime.tdialog,xDetailTime.tnotes,ISNULL(tresp,0)AS tresp,ISNULL(nMoh,0)AS nMoh
	,isnull(nWHag,0)as nWHag,isnull(nWHcl,0)as nWHcl
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup,inbound_id,[user_id]
	,COUNT(cal_id)AS ntotal
	,COUNT(CASE WHEN statuscall_id=1 THEN 1 ELSE NULL END)AS initial
	,COUNT(CASE WHEN statuscall_id=2 THEN 1 ELSE NULL END)AS out_hour 
	,COUNT(CASE WHEN statuscall_id=3 THEN 1 ELSE NULL END)AS out_service
	,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer = ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd 
	,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
	,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
	,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
	,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
	,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS xfer
	,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00'')))THEN cal_xfer ELSE NULL END)AS xfer_que
	,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer <> ''1900-01-01 00:00:00''))THEN 1 ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
	,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
	,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
	,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer = ''1900-01-01 00:00:00'')AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
	,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
	,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
	,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
	,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
	,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0
GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),inbound_id,[user_id])xDetailCount
LEFT JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
	,ISNULL(SUM(cal_tring),0)AS tring,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes
FROM(SELECT timegroup,inbound_id,[user_id]
	,CASE WHEN time_endque<timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss,timegroup_next,time_endque)END AS cal_twait
	,CASE WHEN(time_ring<timegroup_next)THEN cal_txfer WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN cal_txfer - DATEDIFF(ss,timegroup_next,time_ring)ELSE 0 END AS cal_txfer
	,CASE WHEN(time_dialog<timegroup_next)THEN cal_tring WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN cal_tring - DATEDIFF(ss,timegroup_next,time_dialog)ELSE 0 END AS cal_tring
	,CASE WHEN(time_notes<timegroup_next)THEN cal_tdialog WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN cal_tdialog - DATEDIFF(ss,timegroup_next,time_notes)ELSE 0 END AS cal_tdialog
	,CASE WHEN(time_end_call<timegroup_next)THEN cal_tnotas WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN cal_tnotas - DATEDIFF(ss,timegroup_next,time_end_call)ELSE 0 END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
	,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
	,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
	,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
	,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
	,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
	,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
	,*
FROM ccCallsIn with (nolock, index(IX_ccCallsIn))
WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail
UNION
SELECT timegroup_next,inbound_id,[user_id]
	,CASE WHEN time_endque>=timegroup_next THEN DATEDIFF(ss,timegroup_next,time_endque)ELSE 0 END AS cal_twait
	,CASE WHEN(time_ring<timegroup_next)THEN 0 WHEN((time_ring>=timegroup_next)AND(time_endque<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_ring)ELSE cal_txfer END AS cal_txfer
	,CASE WHEN(time_dialog<timegroup_next)THEN 0 WHEN((time_dialog>=timegroup_next)AND(time_ring<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_dialog)ELSE cal_tring END AS cal_tring
	,CASE WHEN(time_notes<timegroup_next)THEN 0 WHEN((time_notes>=timegroup_next)AND(time_dialog<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_notes)ELSE cal_tdialog END AS cal_tdialog
	,CASE WHEN(time_end_call<timegroup_next)THEN 0 WHEN((time_end_call>=timegroup_next)AND(time_notes<timegroup_next))THEN DATEDIFF(ss,timegroup_next,time_end_call)ELSE cal_tnotas END AS cal_tnotas
FROM(SELECT CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)AS timegroup
	,DATEADD(hh,1,CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121)) AS timegroup_next
	,DATEADD(ss,cal_twait,cal_inicio) AS time_endque
	,DATEADD(ss,cal_twait + cal_txfer,cal_inicio) AS time_ring
	,DATEADD(ss,cal_twait + cal_txfer + cal_tring,cal_inicio) AS time_dialog
	,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog,cal_inicio) AS time_notes
	,DATEADD(ss,cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas,cal_inicio) AS time_end_call
	,* FROM ccCallsIn with (nolock, index(IX_ccCallsIn)) WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
GROUP BY timegroup,inbound_id,[user_id])xDetailTime
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
WHERE timegroup>=@from AND timegroup<@to
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
ORDER BY timegroup,inbound_id,[user_id]
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[A_cwRepInbCalif]
@DateG as varchar(20),
@CamAgt as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(500)='''',
@CblDos as varchar(500) = ''''

AS

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(1050)
DECLARE @idioma as bit

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(8000)
DECLARE @sql1 as varchar(8000)
DECLARE @sql2 as varchar(8000)
DECLARE @nodiponibles as varchar(5000)
DECLARE @sumNoDip as varchar(8000)
DECLARE @sumNoDip2 as varchar(8000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)
DECLARE @sSQL1 AS varchar(8000)
DECLARE @sSQL2 AS varchar(8000)
declare @contDet as integer
declare @contSum as integer

set @contDet = 0
set @contSum = 0

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select calif_id, Description from ccTipoCalif
''
    end
    else
    begin
	set @cursor = @cursor +''select calif_id, Description from ccTipoCalif where calif_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.timegroup, nr.inbound_id, nr.user_id'' + char(0x27)+ ''
set @sql1 = ''+char(0x27) + ''''+char(0x27) + ''
set @sql2 = ''+char(0x27) + ''''+char(0x27) + ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip2 = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
		set @contDet = @contDet +1
		set @contSum = @contSum +1
                       	set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		IF @contSum < 125
		begin
                        		set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end
		else
		begin
                        		set @sumNoDip2 = @sumNoDip2 + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end

		IF @contDet < 93
		begin
			set @sql = @sql+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end
		else
		begin
			IF @contDet < 186
			begin
				set @sql1 = @sql1+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
			end
			else
			begin
				set @sql2 = @sql2+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
			end

		end
		Fetch Next From CCampos
		Into  @id, @desc
		End
	End

CLOSE CCampos 
DEALLOCATE CCampos 
''

if @DateG = ''Por Hora'' or @DateG = ''Hour''
begin
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.inbound_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.calif_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.calif_id IN ('' + @CblDos + '')''
end

if @CamAgt = ''Especialidad'' or @CamAgt = ''ACD group''
begin

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT timegroup as Fecha,ccInbound.descripcion AS Especialidad ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( SELECT '' + @sGroupDetail + '' as timegroup, inbound_id''+char(0x27)+'' 
set @sSQL1 = @sumNoDip2  + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL2 =  + ''+char(0x27)+'' FROM ccGenInCalif as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY nr.timegroup, nr.inbound_id, nr.user_id ) a''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', inbound_id) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' LEFT JOIN ccInbound ON (xDetail.inbound_id=ccInbound.inbound_id) order by Fecha, Especialidad''+char(0x27)+''

exec (@sSQL + @sumNoDip + @sSQL1 + @sql + @sql1 + @sql2 + @sSQL2  )

--print(@sSQL)
--print(@sumNoDip)
--print(@sSQL1)
--print(@sql)
--print(@sql1)
--print(@sql2)
--print(@sSQL2 )
''
end
if @CamAgt = ''Agente'' or @CamAgt = ''Agent''
begin

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( SELECT '' + @sGroupDetail + '' as timegroup, [user_id]''+char(0x27)+'' 
set @sSQL1 =  @sumNoDip2 + ''+char(0x27)+'' from ( ''+char(0x27)+'' 
set @sSQL2 =  + ''+char(0x27)+'' FROM ccGenInCalif as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY nr.timegroup, nr.inbound_id, nr.user_id ) a''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', [user_id]) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' LEFT JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) order by Fecha, Agente''+char(0x27)+''

exec (@sSQL + @sumNoDip + @sSQL1 + @sql + @sql1 + @sql2 + @sSQL2  )

--print(@sSQL)
--print(@sumNoDip)
--print(@sSQL1)
--print(@sql)
--print(@sql1)
--print(@sql2)
--print(@sSQL2 )
''
end

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
set @cursor = replace(@cursor, ''Especialidad'', ''Specialty'')
end

exec (@cursor)
--print (@cursor)
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[A_cwRepOutCalif]
@DateG as varchar(20),
@CamAgt as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(500)='''',
@CblDos as varchar(800) = ''''

AS

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(1350)
DECLARE @idioma as bit

set @sWhere =''''

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(8000)
DECLARE @sql1 as varchar(8000)
DECLARE @sql2 as varchar(8000)
DECLARE @nodiponibles as varchar(8000)
DECLARE @sumNoDip as varchar(8000)
DECLARE @sumNoDip2 as varchar(8000)
DECLARE @sumNoDip3 as varchar(8000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)
DECLARE @sSQL1 AS varchar(8000)
DECLARE @sSQL2 AS varchar(8000)
declare @contDet as integer
declare @contSum as integer

set @contDet = 0
set @contSum = 0

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select distinct calif_id, Description from ccTipoCalifOut
''
    end
    else
    begin
	set @cursor = @cursor +''select distinct calif_id, Description from ccTipoCalifOut where calif_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select distinct nr.timegroup, nr.cam_id, nr.user_id'' + char(0x27)+ ''
set @sql1 = ''+char(0x27) + ''''+char(0x27) + ''
set @sql2 = ''+char(0x27) + ''''+char(0x27) + ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip2 = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip3 = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
Begin 

		While @@FETCH_STATUS = 0
		Begin 
			set @contDet = @contDet +1
			set @contSum = @contSum +1
                       	set @nodiponibles = @nodiponibles+ ''+char(0x27)+'', ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		IF @contSum < 123
		begin 
                       		set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
		end
		else
		begin
			if @contSum < 222 begin
                       		set @sumNoDip2 = @sumNoDip2 + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
			end
			else
			begin
                       		set @sumNoDip3 = @sumNoDip3 + ''+char(0x27)+'', sum( ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
			end
		end
		IF @contDet < 89
		begin
			set @sql = @sql+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
                        end
                        else
                        begin
			if  @contDet < 168 begin
				set @sql1 = @sql1+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
			end
			else begin
				set @sql2 = @sql2+''+char(0x27)+'', sum(case when calif_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+'']''+char(0x27)+''
			end
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
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.cam_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.calif_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.calif_id IN ('' + @CblDos + '')''
end

if @CamAgt = ''Campaña'' or @CamAgt = ''Campaign''
begin
set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT timegroup as Fecha, ccCamps.cam_descripcion AS Campana ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( SELECT '' + @sGroupDetail + '' as timegroup, cam_id ''+char(0x27)+''
set @sSQL1 = @sumNoDip3 + ''+char(0x27)+'' from ( ''+char(0x27)+'' 
set @sSQL2 =  + ''+char(0x27)+'' FROM ccGenOutCallCalif as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY nr.timegroup, nr.cam_id, nr.user_id ) as a''+char(0x27) +'' 
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', cam_id ) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+''  LEFT JOIN ccCamps ON (xDetail.cam_id=ccCamps.cam_id) order by Fecha, Campana ''+char(0x27)+''

exec (@sSQL + @sumNoDip + @sumNoDip2  + @sSQL1  + @sql + @sql1 + @sql2 + @sSQL2 )

--print (@sSQL)
--print( @sumNoDip)
--print( @sumNoDip2)
--print (@sSQL1)
--print (@sql)
--print (@sql1)
--print (@sql2)
--print (@sSQL2)
''
end
if @CamAgt = ''Agente'' or @CamAgt = ''Agent''
begin

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''SELECT timegroup as Fecha, apellidoPaterno + ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'' ''+char(0x27)+''+ char(0x27)+''+char(0x27)+''+ isNull( apellidoMaterno, ''+char(0x27)+''+ char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' + char(0x27)+''+char(0x27)+'')+ ''+char(0x27)+'' + char(0x27)+ ''+char(0x27)+'' ''+char(0x27)+'' +char(0x27)+''+char(0x27)+''+  nombres as Agente ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( SELECT '' + @sGroupDetail + '' as timegroup, user_id ''+char(0x27)+''
set @sSQL1 =  @sumNoDip3 + ''+char(0x27)+'' from ( ''+char(0x27)+'' 
set @sSQL2 =   + ''+char(0x27)+'' FROM ccGenOutCallCalif as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL2 = @sSQL2 + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY nr.timegroup, nr.cam_id, nr.user_id ) as a''+char(0x27) +'' 
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', [user_id]  ) xDetail ''+char(0x27)+''
set @sSQL2 = @sSQL2 + ''+char(0x27)+'' LEFT JOIN ccUsers ON (xDetail.[user_id]=ccUsers.[user_id]) order by Fecha, Agente ''+char(0x27)+''

exec (@sSQL + @sumNoDip + @sumNoDip2  + @sSQL1  + @sql + @sql1 + @sql2 + @sSQL2 )

--print (@sSQL)
--print( @sumNoDip)
--print( @sumNoDip2)
--print (@sSQL1)
--print (@sql)
--print (@sql1)
--print (@sql2)
--print (@sSQL2)
''
end

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Campana'', ''Campaign'') 
set @cursor = replace(@cursor, ''Agente'', ''Agent'')
end

exec (@cursor)
--print (@cursor)
'
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set StartTime = ''1900-01-01 00:01:00'',  EndTime= ''1900-01-01 23:59:00''
WHERE Description IN (''ccocallsout'', ''cccallsin'', ''ccLogAgentesNotReady'', ''ccoLogDials'', ''ccocallsoutsource'', ''ccloglogin'', ''cclogAgentesDia'', ''cclogtransfers'')
'
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenSession @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenSession'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInCall @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenInCall'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInCallDNI @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenInCallDNI'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCall @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenOutCall'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenAgent @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenAgent'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenAgentStatusNotReady @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenAgentStatusNotReady'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInSpec @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenInSpec'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInAbnd @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenInAbnd'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInAnsw @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenInAnsw'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenInCalif @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenInCalif'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCamp @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenOutCamp'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCallCalif @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenOutCallCalif'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCallDials @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenOutCallDials'''
	EXEC(@Sql)

	set @Sql='update Exp_Jobs set Readquery = ''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)
EXEC ccspGenOutCstoResumen @start, @end'',writequery= ''*N/A*''
WHERE Description = ''ccspGenOutCstoResumen'''
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInAbnd]
@from AS smalldatetime,
@to AS smalldatetime
AS

 --Delete previous data in case of reprocess HLAS
DELETE ccGenInAbnd WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAbnd (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, inbound_id
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
				, inbound_id
				, statuscall_id
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls
	WHERE (abnd IS NOT NULL) 
	GROUP BY timegroup, inbound_id'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCallDNI]
@from AS smalldatetime,
@to AS smalldatetime
AS

--Sets amount of hours of last day to include in calculations of agent times
DECLARE @HourExtend AS smallint
SELECT @HourExtend = 2

--@fromExtended used to include the times of calls that extend FROM previous day
DECLARE @fromExtended AS smalldatetime
SELECT @fromExtended = DATEADD(hh, -@HourExtend, @from)

DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog
EXEC @tresDelayIn = ccspConfigtresDelayIn

-- Delete previous data in case of reprocess HLAS
DELETE FROM ccGenInCallDNI WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCallDNI (timegroup, dni_id, [user_id]
	, ntotal, nout_hour, nout_service
	, nabnd, nno_agent, nque, ntimeout
	, noverflow, nxfer, nxfer_que
	, nabnd_xfer, nabnd_ring ,nno_answer
	, nabnd_dialog, nanswer, nlost, nmsg
	, nabnd_tres, nansw_tres, tque_max
	, tque, txfer, tring
	, tdialog, tnotes, tresp, ninitial)
SELECT timegroup, dni_id, [user_id], ntotal, nout_hour, nout_service
	, nabnd, nno_agent, nque, ntimeout, noverflow, nxfer, nxfer_que
	, nabnd_xfer, nabnd_ring ,nno_answer, nabnd_dialog, nanswer, nlost, nmsg
	, nabnd_tres, nansw_tres, tque_max, tque, txfer, tring, tdialog, tnotes, tresp, ninitial
FROM (		
	SELECT xDetailTime.timegroup, xDetailTime.dni_id, xDetailTime.[user_id]
		, ISNULL(ntotal, 0) AS ntotal, ISNULL(initial, 0) AS ninitial, ISNULL(out_hour, 0) AS nout_hour, ISNULL(out_service, 0) AS nout_service
		, ISNULL(abnd, 0) AS nabnd, ISNULL(no_agent, 0) AS nno_agent, ISNULL(que, 0) AS nque, ISNULL(timeout, 0) AS ntimeout
		, ISNULL(overflow, 0) AS noverflow, ISNULL(xfer, 0) AS nxfer, ISNULL(xfer_que, 0) AS nxfer_que
		, ISNULL(abnd_xfer, 0) AS nabnd_xfer, ISNULL(abnd_ring, 0) AS nabnd_ring, ISNULL(no_answer, 0) AS nno_answer
		, ISNULL(abnd_dialog, 0) AS nabnd_dialog, ISNULL(answer, 0) AS nanswer, ISNULL(lost, 0) AS nlost, ISNULL(msg, 0) AS nmsg
		, ISNULL(abnd_tres, 0) AS nabnd_tres, ISNULL(answ_tres, 0) AS nansw_tres, ISNULL(tque_max, 0) AS tque_max
		, xDetailTime.tque, xDetailTime.txfer, xDetailTime.tring
		, xDetailTime.tdialog, xDetailTime.tnotes, ISNULL(tresp, 0) AS tresp
	FROM (	
		SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
			, dni_id
			, [user_id]
			, COUNT(cal_id) AS ntotal
			, COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
			, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
			, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
			, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS abnd 
			, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
			, COUNT(CASE WHEN (cal_que > 0) THEN 1 ELSE NULL END) AS que 
			, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
			, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
			, COUNT(CASE WHEN( (statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE NULL END) AS xfer
			, COUNT(CASE WHEN ( (cal_que > 0) and (statuscall_id in (11,15,13,16)  OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00''))  ) THEN cal_xfer ELSE NULL END) AS xfer_que
			, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'')) THEN 1 ELSE NULL END) AS abnd_xfer
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
			, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
			, COUNT(CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
			, COUNT(CASE WHEN ( (statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = ''1900-01-01 00:00:00'') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
			, COUNT(CASE WHEN ( (statuscall_id = 13 AND cal_tdialog > @tresDialog) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS answ_tres
			, ISNULL(MAX(cal_twait), 0) AS tque_max
			, ISNULL(SUM(cal_twait), 0) AS tque
			, ISNULL(SUM(cal_txfer), 0) AS txfer
			, ISNULL(SUM(cal_tdialog), 0) AS tdialog
			, ISNULL(SUM(cal_tnotas), 0) AS tnotes
			, ISNULL(SUM(cal_tring), 0) AS tring
			, ISNULL(SUM(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN (cal_twait + cal_txfer + cal_tring) ELSE NULL END), 0) AS tresp
		FROM ccCallsIn
		WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to AND dni_id > 0
		GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), dni_id, [user_id]
	) xDetailCount
	LEFT JOIN
	(
		SELECT timegroup
			, dni_id
			, [user_id]
			, ISNULL(SUM(cal_twait), 0) AS tque
			, ISNULL(SUM(cal_txfer), 0) AS txfer
			, ISNULL(SUM(cal_tring), 0) AS tring
			, ISNULL(SUM(cal_tdialog), 0) AS tdialog
			, ISNULL(SUM(cal_tnotas), 0) AS tnotes
		FROM ( SELECT timegroup, dni_id, [user_id]
				, CASE WHEN time_endque < timegroup_next THEN cal_twait ELSE cal_twait - DATEDIFF(ss, timegroup_next, time_endque) END AS cal_twait
				, CASE WHEN (time_ring < timegroup_next) THEN cal_txfer WHEN ((time_ring >= timegroup_next) AND (time_endque < timegroup_next)) THEN cal_txfer - DATEDIFF(ss, timegroup_next, time_ring) ELSE 0 END  AS cal_txfer
				, CASE WHEN (time_dialog < timegroup_next) THEN cal_tring WHEN ((time_dialog >= timegroup_next) AND (time_ring < timegroup_next)) THEN cal_tring - DATEDIFF(ss, timegroup_next, time_dialog) ELSE 0 END  AS cal_tring
				, CASE WHEN (time_notes < timegroup_next) THEN cal_tdialog WHEN ((time_notes >= timegroup_next) AND (time_dialog < timegroup_next)) THEN cal_tdialog - DATEDIFF(ss, timegroup_next, time_notes) ELSE 0 END  AS cal_tdialog
				, CASE WHEN (time_end_call < timegroup_next) THEN cal_tnotas WHEN ((time_end_call >= timegroup_next) AND (time_notes < timegroup_next)) THEN cal_tnotas - DATEDIFF(ss, timegroup_next, time_end_call) ELSE 0 END  AS cal_tnotas
			FROM (
				SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
					, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121))  AS timegroup_next
					, DATEADD(ss, cal_twait, cal_inicio)  AS time_endque
					, DATEADD(ss, cal_twait + cal_txfer, cal_inicio)  AS time_ring
					, DATEADD(ss, cal_twait + cal_txfer + cal_tring, cal_inicio)  AS time_dialog
					, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog, cal_inicio)  AS time_notes
					, DATEADD(ss, cal_twait + cal_txfer + cal_tring + cal_tdialog + cal_tnotas, cal_inicio)  AS time_end_call
					, *
				FROM ccCallsIn
				WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to  AND dni_id > 0
			) xDetail
			UNION
			SELECT timegroup_next, dni_id, [user_id]
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
					, *
				FROM ccCallsIn
				WHERE cal_inicio >= @fromExtended AND  cal_inicio < @to  AND dni_id > 0
			) xDetail
		) xTimeDetail
		GROUP BY timegroup, dni_id, [user_id]
	) xDetailTime
	ON (xDetailTime.timegroup = xDetailCount.timegroup AND xDetailTime.dni_id = xDetailCount.dni_id AND xDetailTime.[user_id] = xDetailCount.[user_id])
) xComplete
WHERE timegroup >= @from AND  timegroup < @to
AND NOT (ntotal = 0 AND nout_hour = 0 AND nout_service = 0 AND nabnd = 0 AND nno_agent = 0 AND nque = 0
	AND ntimeout = 0 AND noverflow = 0 AND nxfer = 0 AND nxfer_que = 0 AND nabnd_xfer = 0 AND nabnd_ring = 0
	AND nno_answer = 0 AND nabnd_dialog = 0 AND nanswer = 0 AND nlost = 0 AND nmsg = 0 AND nabnd_tres = 0
	AND nansw_tres = 0 AND tque_max = 0 AND tque = 0 AND txfer = 0 AND tring = 0 AND tdialog = 0 AND tnotes = 0 AND tresp = 0)
ORDER BY timegroup, dni_id, [user_id]
'
	EXEC(@Sql)

	set @Sql='ALTER PROCEDURE [dbo].[ccspGenInCDN]
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @tresRing AS smallint
DECLARE @tresDialog AS smallint
DECLARE @tresDelayIn AS smallint

EXEC @tresRing = ccspConfigTresRing
EXEC @tresDialog = ccspConfigTresDialog
EXEC @tresDelayIn = ccspConfigtresDelayIn

DELETE FROM ccGenInCDN WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCDN (timegroup, inbound_id, ntotal, nout_hour, nout_service, nabnd, nno_agent, ntimeout, noverflow, nabnd_xfer, nabnd_ring ,nno_answer, nabnd_dialog, nanswer, nlost)
select fechaCV as timegroup,inbound_id, count(cal_id) ntotal, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS nout_hour
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS nout_service
					, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = ''1900-01-01 00:00:00''))  THEN 1 ELSE NULL END) AS nabnd, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS nno_agent, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS ntimeout
					, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS noverflow 
					, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL)) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS nabnd_ring
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS nno_answer
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS nabnd_dialog
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS nanswer
					, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS nlost from (
select convert(smalldatetime,convert(varchar(14),cal_inicio,121)+ case when substring(convert(varchar(20),cal_inicio,121),15,2) >= 0 and substring(convert(varchar(20),cal_inicio,121),15,2) < 15 then ''00'' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 15 and substring(convert(varchar(20),cal_inicio,121),15,2) < 30 then ''15'' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 30 and substring(convert(varchar(20),cal_inicio,121),15,2) < 45 then ''30'' when substring(convert(varchar(20),cal_inicio,121),15,2) >= 45 and substring(convert(varchar(20),cal_inicio,121),15,2) <= 59 then ''45'' end + '':00'',121) fechaCV,cal_id,dni_id,cal_puerto,inbound_id,statuscall_id,calif_id,cal_tdialog,cal_tring, cal_que, cal_xfer from cccallsin where cal_inicio > @from and cal_inicio < @to ) a
group by fechaCV,inbound_id
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccTipoUsers]
(
	[TipoUser_id] [int] NOT NULL,
	[descripcion] [varchar](25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccLogAgentesNR_userId] ON [dbo].[ccLogAgentesNotReady] ([User_id]) WITH (FILLFACTOR = 90) ON [PRIMARY];
	CREATE INDEX [IX_ccLogAgentesNR_fecha] ON [dbo].[ccLogAgentesNotReady] ([fecha]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccGenOutCstoRes_userId] ON [dbo].[ccGenOutCstoResumen] ([user_id]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='insert into cctipousers values (1,''Agente'')
insert into cctipousers values (2,''Supervisor CW'')
insert into cctipousers values (4,''Supervisor AVRS'')
insert into cctipousers values (8,''Supervisor CW y AVRS'')

'
	EXEC(@Sql)

	set @Sql='ALTER TABLE ccodialers DROP CONSTRAINT PK_ccodialers'
	EXEC(@Sql)

	set @Sql='alter table ccodialers alter column dialer_id int not null'
	EXEC(@Sql)

	set @Sql='ALTER TABLE ccodialers ADD CONSTRAINT PK_ccodialers PRIMARY KEY CLUSTERED (dialer_id)'
	EXEC(@Sql)

	-- Fix para permitir que se puedan tener mas de 255 calificaciones de salida dentro de la tabla.
 	set @Sql='ALTER TABLE ccTipoCalifOUT DROP CONSTRAINT PK_ccTipoCalifOUT'
	EXEC(@Sql)

 	set @Sql='alter table ccTipoCalifOUT alter column calif_id int not null'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE ccTipoCalifOUT ADD CONSTRAINT PK_ccTipoCalifOUT PRIMARY KEY CLUSTERED (calif_id)'
	EXEC(@Sql)

	set @Sql='DROP INDEX IX_ccCalifCamp ON dbo.ccCalifCamp'
	EXEC(@Sql)

 	set @Sql='alter table ccCalifCamp alter column calif_id int not null'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] 
(
	[calif_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE ccGenOutCallCalif DROP CONSTRAINT PK_ccGenOutCallCalif'
	EXEC(@Sql)

 	set @Sql='alter table ccGenOutCallCalif alter column calif_id int not null'
	EXEC(@Sql)

	set @Sql='ALTER TABLE dbo.ccGenOutCallCalif ADD CONSTRAINT
	PK_ccGenOutCallCalif PRIMARY KEY CLUSTERED 
	(
	timegroup,
	cam_id,
	user_id,
	calif_id
	) WITH( PAD_INDEX = OFF, FILLFACTOR = 90, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='DROP INDEX IX_ccoCallsOut_1 ON dbo.ccoCallsOut'
	EXEC(@Sql)

 	set @Sql='alter table ccoCallsOut alter column calif_id int not null'
	EXEC(@Sql)

 	
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] 
(
	[calif_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

declare @cont as tinyint
SELECT @cont = COLUMNPROPERTY(OBJECT_ID('ccodialers'),'dialer_id','IsIdentity')
if @cont > 0 begin

	set @Sql='truncate table ccodialers'
	EXEC(@Sql)

	set @Sql = 'drop table ccoDialers'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccoDialers](
	[dialer_id] [int] NOT NULL,
	[Descripcion] [varchar](15) NOT NULL,
	[Puerto] [smallint] NOT NULL,
	[Extension] [smallint] NOT NULL CONSTRAINT [DF_ccoDialers_Extension]  DEFAULT (0),
	[Status] [tinyint] NOT NULL CONSTRAINT [DF_ccoDialers_Status]  DEFAULT (0),
	[provedor_id] [smallint] NULL DEFAULT (1),
 CONSTRAINT [PK_ccodialers] PRIMARY KEY NONCLUSTERED 
(
	[dialer_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]'
	EXEC(@Sql)

end 

 	set @Sql='ALTER PROCEDURE [dbo].[ccspGenABorraAntiguo]
@to AS smalldatetime
AS

DELETE ccGenAgent WHERE timegroup < @to
DELETE ccGenInCalif WHERE timegroup < @to
DELETE ccGenInCall WHERE timegroup < @to
DELETE ccGenAgentNotReady WHERE timegroup < @to
DELETE ccGenInAbnd WHERE timegroup < @to
DELETE ccGenInAnsw WHERE timegroup < @to
DELETE ccGenInSpec WHERE timegroup < @to
DELETE ccGenOutCall WHERE timegroup < @to
DELETE ccGenOutCallCalif WHERE timegroup < @to
DELETE ccGenOutCallDials WHERE timegroup < @to
DELETE ccGenOutCamp WHERE timegroup < @to
DELETE ccGenOutCstoResumen WHERE timegroup < @to
DELETE ccGenResumenAgente WHERE fecha < @to
DELETE ccGenSession where login < @to
DELETE ccGen900 WHERE timegroup < @to
DELETE ccGenInCallDNI WHERE timegroup < @to
DELETE ccGenInCDN WHERE timegroup < @to
DELETE ccGenOutDialCamp WHERE timegroup < @to

truncate table cclogInfo
delete from ccLogAgentesDia where fecha < @to
delete from ccLogAgentesNotReady where fecha < @to
delete from ccLogLogin where fecha < @to
delete from ccoLogDials where fecha < @to
delete from ccoCallsOut where cal_inicio < @to
delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -1, @to)
delete from ccCallsin where cal_inicio < @to
delete from ccLogTransfers where fechafin < @to
'
	EXEC(@Sql)

	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''Borra reg. viejos'',
''declare @to datetime 
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mm,-4,getdate()),121)+ '''':00'''',121) 
exec ccspGenABorraAntiguo @to'',''*N/A*'',0,0,10,''01/01/1900 00:10'',''01/01/1900 00:15'',''0000001'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Create PROCEDURE [dbo].[ccspGenOutCallDialsWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenOutCallDialsWG WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallDialsWG (timegroup, idwg, [puerto], tiporesdial_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121) AS timegroup
	, idwg, puerto, tiporesdial_id
	, COUNT(*)
 FROM ccologdials ld, ccGenWorkGroup_logDial_id wg
 WHERE fecha >= @from AND  fecha < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121), idwg, [puerto], tiporesdial_id'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccRIACat_WorkGroup](
	[IDWG] [smallint] NOT NULL,
	[WGName] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[IDWG] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
'
	EXEC(@Sql)

 	set @Sql='CREATE TABLE [dbo].[ccRIAWorkGroupUsers](
	[IDWG] [smallint] NOT NULL,
	[User_id] [smallint] NOT NULL
) ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='ALTER TABLE ccgenagent DROP CONSTRAINT DF_ccGenAgent_tnot_av'
	EXEC(@Sql)

 	set @Sql='alter table ccgenagent alter column tnot_av int not null'
	EXEC(@Sql)

 	set @Sql='CREATE NONCLUSTERED INDEX [DF_ccGenAgent_tnot_av] ON [dbo].[ccgenagent]
(
	[tnot_av] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='Create proc [dbo].[A_cwRep2Calif_WG]
@DateG as varchar(20),	-- Por Hora, Hour, Por Día, Day, Por Periodo, Period
@CamAgt as varchar(20), -- Especialidad, ACD group, Agente, Agent, Grupo de Trabajo, WorkGroup, Area
@fini as varchar(20),	-- Fecha Inicio
@ffin as varchar(20),	-- Fecha Fin
@cbjUno as varchar(500),-- Agrega filtro por inbound_id
@CblDos as varchar(300),-- Agrega filtro por calif_id
@SupID as int=0,		-- Id de supervisor, solo filtra en workgroup y en area
@InOutCalls as bit=0	-- 0:Campañas,Salida / 1:Especialidad,Entrada
as
set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @CamAgt_M varchar(max), @CamAgt_C varchar(max), @Sql varchar(max), @Serv varchar(50)
select @CamAgt_M='''', @CamAgt_C='''', @Serv=valor from ccsettings where setting_id = 22

if @CblDos <> '''' and @cbjUno = ''''
 begin
	While (Charindex('','',@CblDos)>0)
	 Begin 
		Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(Substring(@CblDos,1,Charindex('','',@CblDos)-1))) 
		Set @CblDos = Substring(@CblDos,Charindex('','',@CblDos)+len('',''),len(@CblDos))
	 End 

	Insert Into @RtnValue (Value)
	Select Value = ltrim(rtrim(@CblDos))
 end

else
 begin
	if @InOutCalls = 0
 		insert into @RtnValue select calif_id from ccTipoCalifOUT
 	else
 		insert into @RtnValue select calif_id from ccTipoCalif
 end

if @InOutCalls = 0
 begin
	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifOUT where calif_id in (select value from @RtnValue) order by calif_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when calif_id = '' + CAST(calif_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalifOUT where calif_id in (select value from @RtnValue) order by calif_id
 end

else
 begin
	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalif where calif_id in (select value from @RtnValue) order by calif_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when calif_id = '' + CAST(calif_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([Description], '' '', ''_'')+'']'', '''') 
	from ccTipoCalif where calif_id in (select value from @RtnValue) order by calif_id
 end


select @DateG = case @DateG when ''Por Hora'' then ''H'' when ''Hour'' then ''H'' when ''Por Día'' then ''D'' 
	when ''Day'' then ''D'' when ''Por Periodo'' then ''p'' when ''Period'' then ''p'' end

select @CamAgt = case @CamAgt when ''Campaña'' then ''C'' when ''Campaign'' then ''C'' 
	when ''Especialidad'' then ''E'' when ''ACD group'' then ''E'' when ''Agente'' then ''G'' 
	when ''Agent'' then ''G'' when ''Grupo de Trabajo'' then ''W'' when ''WorkGroup'' then ''W'' when ''Area'' then ''A'' end

if @InOutCalls=0 and @CamAgt=''E''
	set @CamAgt=''C''

if @InOutCalls=1 and @CamAgt=''C''
	set @CamAgt=''E''

IF @CamAgt=''A'' or @CamAgt=''W'' and @SupID=0
	raiserror(''En el caso filtro por Area y Workgroup es necesario el id del supervisor que consulta'', 18, 1)
 
set @Sql=''SELECT timegroup as Fecha '' + case @CamAgt 
	when ''G'' then '', apellidoPaterno + '''' ''''+ isNull( apellidoMaterno, '''' '''')+ '''' ''''+  nombres as Agente ''
	when ''C'' then '', ccCamps.cam_descripcion AS Campana '' when ''E'' then '', ccInbound.descripcion AS Especialidad '' 
	when ''W'' then '', WGName as WorkGroup '' 
	when ''A'' then '', AreaName as Area '' else ''''	end + @CamAgt_M + '' from (SELECT '' + 
	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' 
	when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121) '' end + '' timegroup '' + 
	case @CamAgt when ''G'' then '', [user_id]'' when ''C'' then '', cam_id'' when ''E'' then '', inbound_id'' 
	when ''W'' then '', IDWG'' when ''A'' then '', IDArea'' 
	else '''' end + @CamAgt_C + '' FROM '' + 

	case when @CamAgt in (''G'',''C'') and @InOutCalls = 0 then ''ccGenOutCallCalif''
		 when @CamAgt in (''W'') and @InOutCalls = 0 then ''ccGenOutCallCalifWG''
		 when @CamAgt in (''G'',''C'') and @InOutCalls = 1 then ''ccGenInCalif''
		 when @CamAgt in (''W'') and @InOutCalls = 1 then ''ccGenInCalifWG'' else '''' end + '' WHERE '' +

	case @InOutCalls when 0 then 
		case when @cbjUno <> '''' and @CblDos <> '''' then '' cam_id in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDos + '') and ''
		when @cbjUno <> '''' and @CblDos = '''' then '' cam_id in ( '' + @cbjUno  + '') and ''
		else '''' end 
	else
		case when @cbjUno <> '''' and @CblDos <> '''' then '' inbound_id in ('' + @cbjUno  + '') '' + '' and calif_id IN ('' + @CblDos + '') and ''
		when @cbjUno <> '''' and @CblDos = '''' then '' inbound_id in ( '' + @cbjUno  + '') and ''
		else '''' end 
	end + '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' GROUP BY '' + 

	case @DateG when ''H'' then '' timegroup '' when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' when ''P'' 
	then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121)'' end + case @CamAgt 
	when ''G'' then '', [user_id]'' when ''C'' then '', cam_id'' when ''E'' then '', inbound_id'' 
	when ''W'' then '', IDWG'' when ''A'' then '', IDArea'' 
	else '''' end + '') xDetail  LEFT JOIN '' + case @CamAgt when ''G'' then ''ccUsers ON xDetail.[user_id]=ccUsers.[user_id]'' 
	when ''C'' then ''ccCamps ON xDetail.cam_id=ccCamps.cam_id'' 
	when ''E'' then ''ccInbound ON xDetail.inbound_id=ccInbound.inbound_id'' 
	when ''W'' then ''ccRIACat_WorkGroup wg ON xDetail.IDWG=wg.IDWG''
	when ''A'' then ''ccRIACat_Areas ON xDetail.IDArea=ccRIACat_Areas.IDArea'' 
	else '''' end + '' order by Fecha, '' + case @CamAgt when ''G'' then ''Agente'' 
	when ''C'' then ''Campana'' when ''E'' then ''Especialidad'' 
	when ''W'' then ''WorkGroup'' when ''A'' then ''Area'' else ''''end

	-- Adaptar segun formato de @Serv
--	set @Sql=replace(replace(replace(replace(@Sql, 
--		''ccRIACat_WorkGroup wg'', @Serv+''ccRIACat_WorkGroup wg'')
--		, ''ccRIAAreaWorkGroup aw'', @Serv+''ccRIAAreaWorkGroup aw'')
--		, ''ccRIACampEspWG ce'', @Serv+''ccRIACampEspWG ce'')
--		, ''ccRIAWorkGroupUsers wu'', @Serv+''ccRIAWorkGroupUsers wu'')

begin try
	exec(@Sql)
	--print(@Sql)
end try

begin catch
	declare @error varchar(255)
	set @error=''Se presento un problema al generar el reporte, causa del mismo: "''+ERROR_MESSAGE()+''"''
	select @error
end catch
set nocount off
'
	EXEC(@Sql)

 	set @Sql='Alter TABLE [dbo].[ccgenTelMarcados] WITH NOCHECK ADD 
	CONSTRAINT [PK_ccgenTelMarcados] PRIMARY KEY  CLUSTERED 
	(
		[telefono],
		[fecha],
		[cam_id],
		[cal_key]
	) WITH  FILLFACTOR = 90  ON [PRIMARY] '
	EXEC(@Sql)

 	set @Sql=' CREATE  INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados]([cam_id]) WITH  FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE ccspGenTelMarcados
@from AS smalldatetime,
@to AS smalldatetime
AS

SET NOCOUNT ON

SET ARITHABORT ON

delete from ccgenTelMarcados where fecha >= convert(smalldatetime,convert(varchar(10),@from,121),121) and fecha < convert(smalldatetime,convert(varchar(10),@to,121) + '' 23:58:59'',121)

insert into ccgenTelMarcados
select cal_telefono, timegroup, cal_key, cam_id, count(cal_telefono) as cantidad,DATEPART(Ww, timegroup) as semana  from (
select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, cam_id
 from ccocallsout where cal_inicio >= convert(smalldatetime,convert(varchar(10),@from,121),121) and cal_inicio < convert(smalldatetime,convert(varchar(10),@to,121) + '' 23:58:59'',121) ) a
group by cal_telefono,timegroup,cal_key,cam_id order by 1,4
'
	EXEC(@Sql)

 	set @Sql='CREATE PROCEDURE [dbo].[A_cwReportDialWG]
@DateG as varchar(20),
@fini as varchar(20),
@ffin as varchar(20),
@cbjUno as varchar(600)='''',
@CblDos as varchar(300) = ''''

AS

set nocount on
declare @RtnValue table (Id int identity(1,1), Value nvarchar(100))
declare @CamAgt_M varchar(max), @CamAgt_C varchar(max), @Sql varchar(max), @Serv varchar(50), @idioma as bit
select @CamAgt_M='''', @CamAgt_C='''', @Serv=valor from ccsettings where setting_id = 22
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

if @CblDos <> '''' and @cbjUno = ''''
 begin
	While (Charindex('','',@CblDos)>0)
	 Begin 
		Insert Into @RtnValue (value)
		Select Value = ltrim(rtrim(Substring(@CblDos,1,Charindex('','',@CblDos)-1))) 
		Set @CblDos = Substring(@CblDos,Charindex('','',@CblDos)+len('',''),len(@CblDos))
	 End 

	Insert Into @RtnValue (Value)
	Select Value = ltrim(rtrim(@CblDos))
 end

else
 begin
 		insert into @RtnValue select tipoResDial_id from ccTipoResultadoDial
 end

	select @CamAgt_M=coalesce(@CamAgt_M + '', xDetail.[''+replace([Descripcion], '' '', ''_'')+'']''+ '', dbo.fPorcentaje([''+replace([Descripcion], '' '', ''_'')+''],Total) '' + ''[% ''+replace([Descripcion], '' '', ''_'')+'']'', '''') 
	from ccTipoResultadoDial where tipoResDial_id in (select value from @RtnValue) order by tipoResDial_id

	select @CamAgt_C=coalesce(@CamAgt_C + '', sum(case when tipoResDial_id = '' + CAST(tipoResDial_id as varchar(10)) 
		+ '' then isnull(amount,0) else 0 end)'' + ''[''+replace([Descripcion], '' '', ''_'')+'']'', '''') 
	from ccTipoResultadoDial where tipoResDial_id in (select value from @RtnValue) order by tipoResDial_id

select @CamAgt_C = @CamAgt_C + '', SUM(amount) Total ''

select @DateG = case @DateG when ''Por Hora'' then ''H'' when ''Hour'' then ''H'' when ''Por Día'' then ''D'' 
	when ''Day'' then ''D'' when ''Por Periodo'' then ''p'' when ''Period'' then ''p'' end

set @Sql=''Select timegroup as Fecha, WGName AS WorkGroup '' + @CamAgt_M + '', total from (SELECT distinct'' + 
	case @DateG 
		when ''H'' then '' timegroup '' 
		when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' 
		when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121) '' 
	end + '' timegroup, IDWG '' +  @CamAgt_C + '' FROM ccGenOutCallDialsWG WHERE'' + 

	case 
		when @cbjUno <> '''' and @CblDos <> '''' then '' idwg in ('' + @cbjUno  + '') '' + '' and tipoResDial_id IN ('' + @CblDos + '') and ''
		when @cbjUno <> '''' and @CblDos = '''' then '' idwg in ( '' + @cbjUno  + '') and ''
		else '''' end 

+ '' timegroup >= '''''' + @fini + '''''' AND timegroup < '''''' + @ffin + '''''' GROUP BY '' +

	case @DateG 
		when ''H'' then '' timegroup '' 
		when ''D'' then '' CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) '' 
		when ''P'' then '' CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +''''-01 '''', 121)'' 
	end  + '', idwg) xDetail inner JOIN ccRIACat_WorkGroup wg ON xDetail.IDWG=wg.IDWG''

+ '' order by WGName, timegroup ''

begin try
	exec(@Sql)
	--print(@Sql)
end try

begin catch
	declare @error varchar(255)
	set @error=''Se presento un problema al generar el reporte, causa del mismo: "''+ERROR_MESSAGE()+''"''
	select @error
end catch
set nocount off

'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccGenWorkGroup_Calid'',
''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calIniOut as varchar(15)
declare @calFinOut as varchar(15)
declare @calIniIn as varchar(15)
declare @calFinIn as varchar(15)

select @calIniIn = isnull(max(cal_id),1)  from '''' + @server +''''.dbo.ccGenWorkGroup_Calid  WITH(NOLOCK) WHERE tipo = 1
select @calFinIn = min(cal_id) from (select isnull(min(cal_id),0) cal_id from ccGenWorkGroup_Calid WITH(NOLOCK) where [timestamp] > '''' + char(0x27) + convert(varchar(20),@to,120) + char(0x27) + ''''and tipo = 1 union all select max(cal_id) cal_id from ccGenWorkGroup_Calid WITH(NOLOCK) WHERE tipo = 1) as a where cal_id <> 0
select @calIniOut = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccGenWorkGroup_Calid  WITH(NOLOCK) WHERE tipo = 0
select @calfinOut = min(cal_id) from (select isnull(min(cal_id),0) cal_id from ccGenWorkGroup_Calid WITH(NOLOCK) where [timestamp] > '''' + char(0x27) + convert(varchar(20),@to,120) + char(0x27) + '''' and tipo = 0 union all select max(cal_id) cal_id from ccGenWorkGroup_Calid WITH(NOLOCK) WHERE tipo = 0) as a where cal_id <> 0
''''

set @sql = @sql + ''''select IDWG, cal_id, [user_id], [timestamp], tipo from ccGenWorkGroup_Calid WITH(NOLOCK) WHERE cal_id > @calIniOut and cal_id<= @calfinOut and tipo = 0''''
set @sql = @sql + '''' union all select IDWG, cal_id, [user_id], [timestamp], tipo from ccGenWorkGroup_Calid WITH(NOLOCK) WHERE cal_id > @calIniIn and cal_id<= @calfinIn and tipo = 1''''

--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'',''ccGenWorkGroup_Calid'',1,0,10,''01/01/1900 00:01'',''01/01/1900 23:59'',''1111111'','''','''','''','''','''','''',0,'''','''',1,1)
'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccGenWorkGroup_logdial_id'',
''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @logIni as varchar(15)
declare @logFin as varchar(15)
select @logIni = isnull(max(logDial_ID),0) from '''' + @server +''''.dbo.ccGenWorkGroup_logdial_id WITH(NOLOCK)
select @logFin = min(logdial_id) from (select isnull(min(logDial_ID),0) logdial_id from ccGenWorkGroup_logdial_id with(NOLOCK) where [timestamp] > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(logDial_id) logdial_id from ccGenWorkGroup_logdial_id WITH(NOLOCK)) as a where logdial_id <> 0
''''
set @sql = @sql + ''''select IDWG, logdial_id,cam_id, [timestamp] from ccGenWorkGroup_logdial_id WITH(NOLOCK) where logDial_ID > @logIni AND logDial_ID <= @logFin''''
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'',''ccGenWorkGroup_logdial_id'',1,0,10,''01/01/1900 00:01'',''01/01/1900 23:59'',''1111111'','''','''','''','''','''','''',0,'''','''',1,1)

'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenInCallWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenInCallWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:20'',''01/01/1900 03:25'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenInSpecWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenInSpecWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:25'',''01/01/1900 03:30'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenInAbndWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenInAbndWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:30'',''01/01/1900 03:35'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenInAnswWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenInAnswWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:35'',''01/01/1900 03:40'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenInCalifWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenInCalifWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:40'',''01/01/1900 03:45'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccspGenOutCallWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenOutCallWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:45'',''01/01/1900 03:50'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccGenOutCampWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenOutCampWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:50'',''01/01/1900 03:55'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccGenOutCallCalifWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenOutCallCalifWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 03:55'',''01/01/1900 04:00'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccGenOutCallDialsWG'',
''declare @end as smalldatetime
declare @start as smalldatetime
SELECT @end = CONVERT(datetime, CONVERT(varchar(11), GETDATE(), 121) + ''''00:00'''', 121)
SELECT @start = DATEADD(d, -1, @end)

EXEC ccspGenOutCallDialsWG @start, @end'',''*N/A*'',1,0,10,''01/01/1900 04:00'',''01/01/1900 04:05'',''1111111'','''','''','''','''','''','''',0,'''','''',0,0)'
	EXEC(@Sql)
	
	set @Sql='ALTER PROCEDURE [dbo].[A_cwReportOutCtoProv]
@DateG as varchar(20),
@ffin as varchar(20),
@fini as varchar(20),
@cbjUno as varchar(300)='''',
@CblDos as varchar(150) = ''''
as

declare @cursor as varchar (8000)

DECLARE @sGroupDetail as varchar(105)
DECLARE @sGroup as varchar(105)
DECLARE @sOrder as varchar(75)
DECLARE @sWhere as varchar(520)
DECLARE @idioma as bit
declare @iva varchar(5)
select @iva=valor from ccsettings where setting_id = 25
select @iva=convert(varchar(5),''1.'' + substring(@iva,(len(@iva)-2),3))

set @sWhere =''''
Select @idioma = isnull(valor,0) from ccSettings where setting_id = 23

set @cursor = ''
DECLARE @sql as varchar(4500)
DECLARE @nodiponibles as varchar(3000)
DECLARE @sumNoDip as varchar(3000)
DECLARE @id AS INTEGER
DECLARE @desc AS varchar(50)

DECLARE @sSQL as varchar(8000)
DECLARE @sSQLTot as varchar(8000)

DECLARE CCampos CURSOR FOR 
 ''
    If @CblDos = ''''
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada
''
    end
    else
    begin
	set @cursor = @cursor +''select tipoLlamada_id, descrip from cstoTipoLlamada where tipoLlamada_id in ('' + @CblDos + '' )
''
    end

set @cursor = @cursor + ''set @sql = '' +char(0x27) + ''select  distinct nr.timegroup, nr.provedor_id'' + char(0x27)+ ''
set @nodiponibles = ''+char(0x27) + ''''+char(0x27) + ''
set @sumNoDip = ''+char(0x27) + ''''+char(0x27) + ''
Open CCampos
Fetch Next From CCampos
Into @id, @desc
if @@FETCH_STATUS = 0
	Begin 

		While @@FETCH_STATUS = 0
		Begin 
            set @nodiponibles = @nodiponibles+ ''+char(0x27)+'',['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call] as [Llamadas_''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min] as [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min_Facturados], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], ['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
            --set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
	    set @sumNoDip = @sumNoDip + ''+char(0x27)+'', sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min], sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo], (sum(['' +char(0x27)+'' + REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]))*'' + @iva +'' [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_CostoIVA]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.mins,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Min]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.costo,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Costo]''+char(0x27)+''
			set @sql = @sql+''+char(0x27)+'', sum(case when tipoLlamada_id = ''+char(0x27)+''+ convert(varchar(3),@id)+''+char(0x27)+'' then isnull(nr.amount,0) else 0 end) [''+char(0x27)+''+ REPLACE(REPLACE(REPLACE((@desc),''+char(0x27)+'' ''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''/''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+''),''+char(0x27)+''-''+char(0x27)+'',''+char(0x27)+''_''+char(0x27)+'')+''+char(0x27)+''_Call]''+char(0x27)+''
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
   set @sGroupDetail = ''timegroup''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
end
if @DateG = ''Por Día'' or @DateG = ''Day''
begin
   set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(10), timegroup, 121), 121) ''
   set @sGroup = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121) +''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01''+ char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
end
if @DateG = ''Por Periodo'' or @DateG = ''Period''
begin
    set @sGroupDetail = ''CONVERT(smalldatetime, CONVERT(varchar(7), timegroup, 121)  +'' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+ ''-01 '' + char(0x27) + '' + char(0x27)+ '' +char(0x27)+'', 121)''
    set @sGroup = '' 0 ''
end

If @cbjUno <> ''''
begin
    set @sWhere = '' nr.provedor_id in ( '' + @cbjUno  + '') ''
    If @CblDos <> ''''
    begin
       set @sWhere = @sWhere + ''and nr.tipoLlamada_id IN ('' + @CblDos + '')''
    end
end

If @CblDos <> '''' and @cbjUno = ''''
begin
    set @sWhere = '' nr.tipoLlamada_id IN ('' + @CblDos + '')''
end

set @cursor = @cursor + '' set @sSQL = ''+char(0x27)+''(SELECT timegroup as Fecha, cstoProvedor.descrip AS Proveedor ''+char(0x27)+'' + @nodiponibles + ''+char(0x27)+'' from ( ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' SELECT '' + @sGroupDetail + '' as timegroup, provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQL = @sSQL + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQL = @sSQL + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' GROUP BY '' + @sGroupDetail + '', provedor_id ) xDetail ''+char(0x27)+''
set @sSQL = @sSQL + ''+char(0x27)+'' LEFT JOIN cstoProvedor ON (xDetail.provedor_id=cstoProvedor.provedor_id) ) ''+char(0x27)+''''

set @cursor = @cursor + '' set @sSQLTot = ''+char(0x27)+'' union all ( SELECT getdate() as timegroup, ''+char(0x27)+''+char(0x27)+''+char(0x27)+''Total''+char(0x27)+''+char(0x27)+''+char(0x27)+'' as provedor_id ''+char(0x27)+'' + @sumNoDip + ''+char(0x27)+'' from ( ''+char(0x27)+'' + @sql
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' FROM ccGenOutCstoResumen as nr WHERE nr.timegroup >= ''+ char(0x27)+ ''+ char(0x27)+ '' +char(0x27)+ @fini +char(0x27) + '' + char(0x27) + ''+ char(0x27)+ '' AND nr.timegroup < ''+ char(0x27)+ '' + char(0x27) + ''+char(0x27) +   @ffin +char(0x27)+  '' + char(0x27) +''+ char(0x27) +''''+ char(0x27) +''
''

If @sWhere <> ''''
begin
set @cursor = @cursor + ''set  @sSQLTot = @sSQLTot + '' + char(0x27) + '' AND '' + @sWhere + char(0x27)
End

set @cursor = @cursor + ''
set @sSQLTot = @sSQLTot + ''+char(0x27)+'' GROUP BY timegroup, provedor_id ) a) order by Fecha, Proveedor''+char(0x27)+''


exec ( @sSQL + @sSQLTot)
--print (@sSQL)
--print (@sSQLTot)
''

if @idioma = 1
begin
set @cursor = replace(@cursor, ''Llamadas'', ''Calls'')
set @cursor = replace(@cursor, ''Min_Facturados'', ''Rated_Min'')
set @cursor = replace(@cursor, ''_CostoIVA'', ''_Tax'')
set @cursor = replace(@cursor, ''_Costo'', ''_Cost'')
set @cursor = replace(@cursor, ''Fecha'', ''Date'') 
set @cursor = replace(@cursor, ''Proveedor'', ''Supplier'')
end

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

