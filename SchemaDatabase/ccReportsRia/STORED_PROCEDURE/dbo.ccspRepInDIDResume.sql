CREATE PROCEDURE [dbo].[ccspRepInDIDResume]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

set nocount on
set ansi_nulls off 
set ANSI_WARNINGS off

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

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

if @action = 1
	begin

		CREATE TABLE [dbo].[#ccGenInCallDNI](
			[timegroup] [smalldatetime] NOT NULL,
			[dni_id] [smallint] NOT NULL,
			[user_id] [smallint] NOT NULL,
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
		-- CONSTRAINT [PK_ccGenInCallDNI] PRIMARY KEY CLUSTERED 
		--(
		--	[timegroup] ASC,
		--	[dni_id] ASC,
		--	[user_id] ASC
		--)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
		) ON [PRIMARY]

		INSERT INTO #ccGenInCallDNI (timegroup, dni_id, [user_id]
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
				SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup
					, dni_id
					, [user_id]
					, COUNT(cal_id) AS ntotal
					, COUNT(CASE WHEN statuscall_id = 1 THEN 1 ELSE NULL END) AS initial
					, COUNT(CASE WHEN statuscall_id = 2 THEN 1 ELSE NULL END) AS out_hour 
					, COUNT(CASE WHEN statuscall_id = 3 THEN 1 ELSE NULL END) AS out_service
					, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer = '1900-01-01 00:00:00'))  THEN 1 ELSE NULL END) AS abnd 
					, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
					, COUNT(CASE WHEN (cal_que > 0) THEN 1 ELSE NULL END) AS que 
					, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
					, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
					, COUNT(CASE WHEN( (statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer <> '1900-01-01 00:00:00') ) THEN 1 ELSE NULL END) AS xfer
					, COUNT(CASE WHEN ( (cal_que > 0) and (statuscall_id in (11,15,13,16)  OR (statuscall_id = 6 AND cal_xfer <> '1900-01-01 00:00:00'))  ) THEN cal_xfer ELSE NULL END) AS xfer_que
					, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer <> '1900-01-01 00:00:00')) THEN 1 ELSE NULL END) AS abnd_xfer
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
					, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
					, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
					, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
					, COUNT(CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
					, COUNT(CASE WHEN ( (statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer = '1900-01-01 00:00:00') AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
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
				GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121), dni_id, [user_id]
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
						SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup
							, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121))  AS timegroup_next
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
						SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121) AS timegroup
							, DATEADD(hh, 1, CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + ':00', 121))  AS timegroup_next
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
		
		delete [RepInDIDResume] with(rowlock)
		where date >= @from AND date < @to 

		insert into [RepInDIDResume]
		select timegroup as date, a.dni_id as dnisId,  CASE WHEN ccd.dni_descripcion = '' then  convert(varchar,min(ccd.dni_numero)) else ccd.dni_descripcion end as dnis, 
			   (CASE WHEN ccd.dni_descripcion = '' then  convert(varchar,min(ccd.dni_numero)) else ccd.dni_descripcion end) + '_Count' as dnis_count, sum(nanswer) as [count]
		, datepart(yyyy,CONVERT(varchar(20), timegroup, 120)) as [year]
		, datepart(mm,CONVERT(varchar(20), timegroup, 120)) as [month]
		, datepart(dd,CONVERT(varchar(20), timegroup, 120)) as [day]
		, datepart(hh,CONVERT(varchar(20), timegroup, 120)) as [hour]
		, datepart(mi,CONVERT(varchar(20), timegroup, 120)) as [minutes] 
		from dbo.#ccGenInCallDNI a
		left join ccdnis ccd on (a.dni_id = ccd.dni_id)
		where timegroup >= @from
		and timegroup < @to		
		group by timegroup,a.dni_id,dni_descripcion
		having sum(nanswer) > 0

		drop table #ccGenInCallDNI

	end