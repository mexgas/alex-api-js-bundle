/*
Autor: Jesus Gallardo
Fecha: 2014/08/08
Descripcion:

	Se Modifica la tabla ccGenAgent para agregar columna tmanualcall
	Se crea indice IX_ccCallsIn_4 en  ccCallsIn 
	Se crea indice IX_ccGenInCallWG en  ccGenInCallWG
	Se crea indice IX_ccGenSession en  ccGenSession
	Se crea indice IX_ccgenTelMarcados_1 en  ccgenTelMarcados

	Se modifica SP ccspGenAgent para performance
	Se modifica SP ccspGenInCallWG para performance
	Se modifica SP ccspGenTelMarcados para performance
	Se modifica Vista ccGenViewAgent para performance

Version requerida: 52
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '53'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Alter Table ccGenAgent'
	set @sql='if not exists(select * FROM INFORMATION_SCHEMA.COLUMNS AS c1 where c1.column_name = ''tmanualcall'' and c1.table_name = ''ccGenAgent'') 	 alter table ccGenAgent add tmanualcall smallint not null default(0)'
	
	EXEC(@Sql)
	

	set @process = 'Create Index IX_ccCallsIn_4 -- ccCallsIn'
	set @sql='CREATE NONCLUSTERED INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn]
(
	[cal_id] ASC,
	[cal_Inicio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create Index IX_ccGenInCallWG -- ccGenInCallWG'
	set @sql='CREATE NONCLUSTERED INDEX [IX_ccGenInCallWG] ON [dbo].[ccGenInCallWG]
(
	[timegroup] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create Index IX_ccGenSession -- ccGenSession'
	set @sql='CREATE NONCLUSTERED INDEX [IX_ccGenSession] ON [dbo].[ccGenSession]
(
	[user_id] ASC,
	[login] ASC,
	[logout] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]'
	
	EXEC(@Sql)

	set @process = 'Create Index IX_ccgenTelMarcados_1 -- ccgenTelMarcados'
	set @sql='CREATE NONCLUSTERED INDEX [IX_ccgenTelMarcados_1] ON [dbo].[ccgenTelMarcados]
(
	[fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]'
	
	EXEC(@Sql)


	set @process = 'Alter SP -- ccspGenAgent'
	set @sql='
ALTER PROCEDURE [dbo].[ccspGenAgent]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenAgent with(rowlock) WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenAgent(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall)
SELECT timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl,tmanualCall
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring + tmanualCall) AS ttot,nMoh,nWHag,nWHcl,tmanualCall
		 FROM(
			SELECT 
				xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,tunknown,nother
				,ISNULL(SUM(ccGenViewInCall.txfer),0)+ ISNULL(SUM(ccGenViewOutCall.txfer),0)as txfer
				,ISNULL(SUM(ccGenViewInCall.tdialog),0)+ ISNULL(SUM(ccGenViewOutCall.tdialog),0)as tdialog
				,ISNULL(SUM(ccGenViewInCall.tnotes),0)+ ISNULL(SUM(ccGenViewOutCall.tnotes),0)as tnotes
				,ISNULL(SUM(ccGenViewInCall.tring),0)+ ISNULL(SUM(ccGenViewOutCall.tring),0)as tring
				,ISNULL(SUM(ccGenViewInCall.nMoh),0)+ ISNULL(SUM(ccGenViewOutCall.nMoh),0)as nMoh
				,ISNULL(SUM(ccGenViewInCall.nWHag),0)+ ISNULL(SUM(ccGenViewOutCall.nWHag),0)as nWHag
				,ISNULL(SUM(ccGenViewInCall.nWHcl),0)+ ISNULL(SUM(ccGenViewOutCall.nWHcl),0)as nWHcl
				,tmanualCall
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM ccGenSession with(nolock, index(IX_ccGenSession))
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM ccGenSession with(nolock, index(IX_ccGenSession))
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM ccGenSession with(nolock, index(IX_ccGenSession))
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM ccGenSession with(nolock, index(IX_ccGenSession))
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND login<DATEADD(hh,1,xTimeDetail.timegroup)AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t4
			
			 FROM(
					SELECT CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121)AS timegroup
						,ccLogAgentesDia.[user_id]
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=1)THEN tStatus ELSE NULL END),0)AS tunknown
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=2)THEN tStatus ELSE NULL END),0)AS tnot_av
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=3)THEN tStatus ELSE NULL END),0)AS tav
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=11)THEN tStatus ELSE NULL END),0)AS tprob
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=7)THEN tStatus ELSE NULL END),0)AS tother
						,COUNT(CASE WHEN(tipostatusage_id=7)THEN 1 ELSE NULL END)AS nother
						,ISNULL(SUM(CASE WHEN(tipostatusage_id=21)THEN tStatus ELSE NULL END),0)AS tmanualcall
					 FROM ccLogAgentesDia with(nolock, index(ccLogAgentesDia_fecAsc))
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN ccGenViewInCall ON(xTimeDetail.timegroup=ccGenViewInCall.timegroup AND xTimeDetail.[user_id]=ccGenViewInCall.[user_id])
					LEFT OUTER JOIN ccGenViewOutCall ON(xTimeDetail.timegroup=ccGenViewOutCall.timegroup AND xTimeDetail.[user_id]=ccGenViewOutCall.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown, tmanualcall
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]'
	
	EXEC(@Sql)

	set @process = 'Alter SP -- ccspGenInCallWG'
	set @sql='ALTER PROCEDURE [dbo].[ccspGenInCallWG]
@from AS smalldatetime,
@to AS smalldatetime
AS

DECLARE @HourExtend AS smallint,@fromExtended AS smalldatetime
SELECT @HourExtend=2,@fromExtended=DATEADD(hh,-@HourExtend,@from)
DECLARE @tresRing AS smallint,@tresDialog AS smallint,@tresDelayIn AS smallint

EXEC @tresRing=ccspConfigTresRing
EXEC @tresDialog=ccspConfigTresDialog
EXEC @tresDelayIn=ccspConfigtresDelayIn

DELETE ccGenInCallWG with(rowlock) WHERE timegroup >= @from AND timegroup < @to

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
				 FROM ccCallsIn ci with(index(IX_ccCallsIn_4),nolock), ccRIAWorkGroup_Calid wg
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
							FROM ccCallsIn ci with(index(IX_ccCallsIn_4),nolock), ccRIAWorkGroup_Calid wg
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
							FROM ccCallsIn ci with(index(IX_ccCallsIn_4),nolock), ccRIAWorkGroup_Calid wg
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

	set @process = 'Alter SP -- ccspGenTelMarcados'
	set @sql='ALTER PROCEDURE [dbo].[ccspGenTelMarcados]
@from AS smalldatetime,
@to AS smalldatetime
AS

SET NOCOUNT ON

SET ARITHABORT ON

delete from ccgenTelMarcados with(rowlock)
where fecha >= convert(smalldatetime,convert(varchar(10),@from,121),121) 
and fecha < convert(smalldatetime,convert(varchar(10),@to,121) + '' 23:59:59'',121)

insert into ccgenTelMarcados
select cal_telefono, timegroup, cal_key, cam_id, count(cal_telefono) as cantidad,DATEPART(Ww, timegroup) as semana  
from(select cal_telefono, convert(smalldatetime,convert(varchar(10),cal_inicio,121),121) as timegroup, cal_key, cam_id
	 from ccocallsout with(index(IX_ccoCallsOut_2), nolock)
	 where cal_inicio >= convert(smalldatetime,convert(varchar(10),@from,121),121) 
	 and cal_inicio < convert(smalldatetime,convert(varchar(10),@to,121) + '' 23:59:59'',121)) a
group by cal_telefono, timegroup, cal_key, cam_id 
order by cal_telefono, cam_id'
	
	EXEC(@Sql)

	set @process = 'Alter VIEW -- ccGenViewAgent'
	set @sql='ALTER VIEW [dbo].[ccGenViewAgent]
AS
SELECT        CASE WHEN ccGEnAgent.timegroup IS NOT NULL THEN ccGEnAgent.timegroup WHEN ccGenViewIncall.timegroup IS NOT NULL THEN ccGenViewIncall.timegroup WHEN ccGenViewOutcall.timegroup IS NOT NULL 
                         THEN ccGenViewOutcall.timegroup ELSE 0 END AS timegroup, CASE WHEN ccGEnAgent.user_id IS NOT NULL THEN ccGEnAgent.user_id WHEN ccGenViewIncall.user_id IS NOT NULL 
                         THEN ccGenViewIncall.user_id WHEN ccGenViewOutcall.user_id IS NOT NULL THEN ccGenViewOutcall.user_id ELSE - 1 END AS user_id, ISNULL(dbo.ccGenViewInCall.nxfer, 0) AS nxfer_in, 
                         ISNULL(dbo.ccGenViewInCall.nanswer, 0) AS nanswer_in, ISNULL(dbo.ccGenViewInCall.nabnd_xfer, 0) AS nabnd_xfer_in, ISNULL(dbo.ccGenViewInCall.nabnd_ring, 0) AS nabnd_ring_in, 
                         ISNULL(dbo.ccGenViewInCall.nabnd_dialog, 0) AS nabnd_dlg_in, ISNULL(dbo.ccGenViewInCall.nabnd_xfer, 0) + ISNULL(dbo.ccGenViewInCall.nabnd_ring, 0) + ISNULL(dbo.ccGenViewInCall.nabnd_dialog, 0) 
                         AS abnd_a_xfer_in, ISNULL(dbo.ccGenViewInCall.nno_answer, 0) AS nno_answer_in, ISNULL(dbo.ccGenViewInCall.nlost, 0) AS nlost_in, ISNULL(dbo.ccGenViewInCall.tdialog, 0) AS tdialog_in, 
                         ISNULL(dbo.ccGenViewInCall.tnotes, 0) AS tnotes_in, ISNULL(dbo.ccGenViewInCall.tring, 0) AS tring_in, ISNULL(dbo.ccGenViewInCall.txfer, 0) AS txfer_in, ISNULL(dbo.ccGenViewOutCall.nxfer, 0) AS nxfer_out, 
                         ISNULL(dbo.ccGenViewOutCall.nanswer, 0) AS nanswer_out, ISNULL(dbo.ccGenViewOutCall.nabnd_xfer, 0) AS nabnd_xfer_out, ISNULL(dbo.ccGenViewOutCall.nabnd_ring, 0) AS nabnd_ring_out, 
                         ISNULL(dbo.ccGenViewOutCall.nabnd_dialog, 0) AS nabnd_dlg_out, ISNULL(dbo.ccGenViewOutCall.nabnd_xfer, 0) + ISNULL(dbo.ccGenViewOutCall.nabnd_ring, 0) + ISNULL(dbo.ccGenViewOutCall.nabnd_dialog, 0) 
                         AS abnd_a_xfer_out, ISNULL(dbo.ccGenViewOutCall.nno_answer, 0) AS nno_answer_out, ISNULL(dbo.ccGenViewOutCall.nlost, 0) AS nlost_out, ISNULL(dbo.ccGenViewOutCall.tdialog, 0) AS tdialog_out, 
                         ISNULL(dbo.ccGenViewOutCall.tnotes, 0) AS tnotes_out, ISNULL(dbo.ccGenViewOutCall.tring, 0) AS tring_out, ISNULL(dbo.ccGenViewOutCall.txfer, 0) AS txfer_out, ISNULL(dbo.ccGenAgent.nother, 0) AS nother, 
                         ISNULL(dbo.ccGenAgent.tunknown, 0) AS tunknown, ISNULL(dbo.ccGenAgent.tnot_av, 0) AS tnot_av, ISNULL(dbo.ccGenAgent.tlog, 0) AS tlog, ISNULL(dbo.ccGenAgent.treq, 0) AS treq, ISNULL(dbo.ccGenAgent.tav, 
                         0) AS tav, ISNULL(dbo.ccGenAgent.tother, 0) AS tother, ISNULL(dbo.ccGenAgent.tprob, 0) AS tprob, ISNULL(dbo.ccGenViewInCall.nMoh, 0) AS nMoh_in, ISNULL(dbo.ccGenViewOutCall.nMoh, 0) AS nMoh_out, 
                         ISNULL(dbo.ccGenViewInCall.nWHag, 0) AS nWHag_in, ISNULL(dbo.ccGenViewOutCall.nWHag, 0) AS nWHag_out, ISNULL(dbo.ccGenViewInCall.nWHcl, 0) AS nWHcl_in, ISNULL(dbo.ccGenViewOutCall.nWHcl, 0) 
                         AS nWHcl_out, ISNULL(dbo.ccGenAgent.tmanualcall, 0) AS tmanualcall
FROM            dbo.ccGenAgent FULL OUTER JOIN
                         dbo.ccGenViewInCall ON dbo.ccGenViewInCall.timegroup = dbo.ccGenAgent.timegroup AND dbo.ccGenViewInCall.user_id = dbo.ccGenAgent.user_id FULL OUTER JOIN
                         dbo.ccGenViewOutCall ON dbo.ccGenViewOutCall.timegroup = dbo.ccGenAgent.timegroup AND dbo.ccGenViewOutCall.user_id = dbo.ccGenAgent.user_id'
	
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
--		Generamos nueva version
		exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
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
