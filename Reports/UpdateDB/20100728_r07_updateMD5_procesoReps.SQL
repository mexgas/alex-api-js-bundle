/*
Autor: Armando Rodriguez
Fecha: 2010/07/09
Descripcion: modificacion para correr completamente todo el proceso de los reportes desde ccreports, ademas se actualiza la version de md5 que utiliza la base de datos
Version requerida: 6
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '7'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='CREATE TABLE [dbo].[ccLogLogin](
	[User_id] [smallint] NOT NULL,
	[Extension] [varchar](7) NOT NULL,
	[TipoMov] [tinyint] NOT NULL,
	[fecha] [datetime] NOT NULL CONSTRAINT [DF_ccLogLogin_fecha]  DEFAULT (getdate())
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [ccLogLogin_user] ON [dbo].[ccLogLogin] 
(
	[User_id] ASC
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [ccLogLogin_tipomov] ON [dbo].[ccLogLogin] 
(
	[TipoMov] ASC
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [ccLogLogin_fecha] ON [dbo].[ccLogLogin] 
(
	[fecha] ASC
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='ALTER FUNCTION [dbo].[md5] (@data varchar(255)) 
RETURNS CHAR(32) AS
BEGIN
  return UPPER(SUBSTRING(master.dbo.fn_varbintohexstr(HashBytes(''MD5'', lower(@data))), 3, 32))  
END
'
	EXEC(@Sql)

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''ccloglogin'',
''declare @server varchar(200) 
declare @sql varchar(8000) 
declare @from datetime 
declare @to datetime 
select @server = valor from ccsettings where setting_id = 22 
set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121) 
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121) 
set @sql = ''''declare @fec as varchar(20) 
select @fec = convert(varchar(20),isnull(convert(datetime,convert(varchar(20),dateadd(ss,1,max(fecha)),120),120),getdate()-1),120) from '''' + @server +''''.dbo.ccLogLogin WITH(NOLOCK) ''''
set @sql = @sql + ''''SELECT User_id, Extension, TipoMov, fecha FROM ccLogLogin WITH(NOLOCK) WHERE fecha >= @fec AND fecha < '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) 
--print @sql 
exec(@sql) 
exec ccsp_LogInfo @sql, -19'',''ccLogLogin'',1,0,10,''01/01/1900 06:40'',''01/01/1900 23:40'',''1111111'','''','''','''','''','''','''',0,'''','''',1,1)'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenSession]
	@from as smalldatetime,
	@to as smalldatetime
	AS
	delete  from ccGenSession where login >= @from and login<@to

	INSERT INTO ccGenSession ([user_id], extension, login, logout)
	SELECT uid, max(ext), login, max(logout)
	FROM 
		(SELECT uid, ext, login, ISNULL(logout, (SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(ccLogLogin_fecha))
		WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout 
		FROM
			(SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout
			FROM 
				(SELECT uid, ext, MAX(login) as login, logout
				FROM
					(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha) 
					FROM ccLogLogin subLogin with (nolock, index(ccLogLogin_fecha)) WHERE subLogin.tipomov = 0 
					AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout] 
					FROM ccLogLogin Login with (nolock, index(ccLogLogin_fecha))
					WHERE login.fecha >= dateadd(dd, -5, @from) and tipomov = 1
					GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail 
				WHERE logout IS NOT NULL GROUP BY uid, ext, logout) Login 
			RIGHT OUTER JOIN ccLogLogin  with (nolock, index(ccLogLogin_fecha))
			ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login AND ccLogLogin.extension = Login.ext)
			WHERE tipomov = 1
			and ccLogLogin.fecha >= dateadd( dd, -5, @from )) Det 
		) LoginDetail 
	WHERE logout IS NOT NULL
	AND login >= @from and login < @to
	GROUP BY uid, login'
	EXEC(@Sql)

	-- Fix para reporte de no disponibles / cuadra el tiempo con el concentrado, agentes/tiempos
 			set @Sql='alter table ccLogAgentesNotReady drop constraint DF_ccLogAgentesNotReady_fecha'
		EXEC(@Sql)

 			set @Sql='alter table ccLogAgentesNotReady alter column fecha datetime'
		EXEC(@Sql)

 			set @Sql='alter table ccLogAgentesNotReady add constraint DF_ccLogAgentesNotReady_fecha DEFAULT (getdate()) for fecha'
		EXEC(@Sql)

	set @Sql='Create PROCEDURE [dbo].[ccspGenInCall]
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
	,COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer IS NULL))THEN 1 ELSE NULL END)AS abnd 
	,COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END)AS no_agent
	,COUNT(CASE WHEN(cal_que>0)THEN 1 ELSE NULL END)AS que 
	,COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END)AS timeout
	,COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END)AS overflow
	,COUNT(CASE WHEN((statuscall_id in(11,15,13,16))OR(statuscall_id=6 AND cal_xfer IS NOT NULL))THEN 1 ELSE NULL END)AS xfer
	,COUNT(CASE WHEN((cal_que>0)and(statuscall_id in(11,15,13,16)OR(statuscall_id=6 AND cal_xfer IS NOT NULL)))THEN cal_xfer ELSE NULL END)AS xfer_que
	,COUNT(CASE WHEN((statuscall_id=11)OR(statuscall_id=6 AND cal_xfer IS NOT NULL))THEN 1 ELSE NULL END)AS abnd_xfer
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN 1 ELSE NULL END)AS abnd_ring
	,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END)AS no_answer
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog<=@tresDialog))THEN 1 ELSE NULL END)AS abnd_dialog
	,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END)AS answer
	,COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END)AS lost
	,COUNT(CASE WHEN(statuscall_id IN(9,10,12,14))THEN 1 ELSE NULL END)AS msg
	,COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer IS NULL)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS abnd_tres
	,COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END)AS answ_tres
	,ISNULL(MAX(cal_twait),0)AS tque_max,ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
	,ISNULL(SUM(cal_tdialog),0)AS tdialog,ISNULL(SUM(cal_tnotas),0)AS tnotes,ISNULL(SUM(cal_tring),0)AS tring
	,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_twait + cal_txfer + cal_tring)ELSE NULL END),0)AS tresp,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh
	,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
FROM ccCallsIn
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
FROM ccCallsIn
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
	,* FROM ccCallsIn WHERE cal_inicio>=@fromExtended AND cal_inicio<@to AND INBOUND_ID>0)xDetail)xTimeDetail
GROUP BY timegroup,inbound_id,[user_id])xDetailTime
ON(xDetailTime.timegroup=xDetailCount.timegroup AND xDetailTime.inbound_id=xDetailCount.inbound_id AND xDetailTime.[user_id]=xDetailCount.[user_id]))xComplete
WHERE timegroup>=@from AND timegroup<@to
AND NOT(ntotal=0 AND nout_hour=0 AND nout_service=0 AND nabnd=0 AND nno_agent=0 AND nque=0
AND ntimeout=0 AND noverflow=0 AND nxfer=0 AND nxfer_que=0 AND nabnd_xfer=0 AND nabnd_ring=0
AND nno_answer=0 AND nabnd_dialog=0 AND nanswer=0 AND nlost=0 AND nmsg=0 AND nabnd_tres=0
AND nansw_tres=0 AND tque_max=0 AND tque=0 AND txfer=0 AND tring=0 AND tdialog=0 AND tnotes=0 AND tresp=0)
ORDER BY timegroup,inbound_id,[user_id]'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInCallDNI]
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
			, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END) AS abnd 
			, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS no_agent
			, COUNT(CASE WHEN (cal_que > 0) THEN 1 ELSE NULL END) AS que 
			, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS timeout
			, COUNT(CASE WHEN (statuscall_id = 8) THEN 1 ELSE NULL END) AS overflow
			, COUNT(CASE WHEN( (statuscall_id in (11,15,13,16)) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL) ) THEN 1 ELSE NULL END) AS xfer
			, COUNT(CASE WHEN ( (cal_que > 0) and (statuscall_id in (11,15,13,16)  OR (statuscall_id = 6 AND cal_xfer IS NOT NULL))  ) THEN cal_xfer ELSE NULL END) AS xfer_que
			, COUNT(CASE WHEN ((statuscall_id = 11) OR (statuscall_id = 6 AND cal_xfer IS NOT NULL)) THEN 1 ELSE NULL END) AS abnd_xfer
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring <= @tresRing)) THEN 1 ELSE NULL END) AS abnd_ring
			, COUNT(CASE WHEN ((statuscall_id = 15) AND (cal_tring > @tresRing)) THEN 1 ELSE NULL END) AS no_answer
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  <= @tresDialog)) THEN 1 ELSE NULL END) AS abnd_dialog
			, COUNT(CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
			, COUNT(CASE WHEN (statuscall_id = 16) THEN 1 ELSE NULL END) AS lost
			, COUNT(CASE WHEN (statuscall_id IN (9, 10, 12, 14)) THEN 1 ELSE NULL END) AS msg
			, COUNT(CASE WHEN ( (statuscall_id IN (5,6) AND cal_que > 0 AND cal_xfer IS NULL) AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE NULL END) AS abnd_tres
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

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCall]
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
					,COUNT(CASE WHEN(statuscall_id=6)THEN cal_id ELSE NULL END)AS hung_up --NO se usa,así que es igual a total para las llamadas sin agente asignada(->agente 0)
					,COUNT(CASE WHEN(statuscall_id=4)THEN cal_id ELSE NULL END)AS no_agent
					,COUNT(CASE WHEN(statuscall_id>=10)THEN cal_id ELSE NULL END)AS xfer
					,COUNT(CASE WHEN(statuscall_id=11)THEN cal_id ELSE NULL END)AS abnd_xfer
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring<=@tresRing))THEN cal_id ELSE NULL END)AS abnd_ring
					,COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN cal_id ELSE NULL END)AS no_answer
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog <=@tresDialog))THEN cal_id ELSE NULL END)AS abnd_dialog
					,COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN cal_id ELSE NULL END)AS answer
					,COUNT(CASE WHEN(statuscall_id=16)THEN cal_id ELSE NULL END)AS lost
					,ISNULL(SUM(cal_txfer),0)AS txfer
					,ISNULL(SUM(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN(cal_txfer + cal_tring)ELSE NULL END),0)AS tresp
					,ISNULL(sum(case when cal_tMoh>0 then 1 else 0 end),0)as nMoh,ISNULL(SUM(CASE WHEN cal_whoHung>0 THEN 1 ELSE 0 END),0)as nWHag,ISNULL(SUM(CASE WHEN cal_whoHung=0 THEN 1 ELSE 0 END),0)as nWHcl
				 FROM ccoCallsOut
					WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
					-- para contar bien las llamadas manuales
					and cal_manual in(0,2)
				 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),cal_inicio,121)+ '':00'',121),cam_id,[user_id]
			)xDetailCount
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
							FROM ccoCallsOut
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
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
							FROM ccoCallsOut
							WHERE cal_inicio>=@fromExtended AND cal_inicio<@to
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
 ORDER BY timegroup,cam_id,[user_id]
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccLogAgentesDia](
	[User_id] [smallint] NOT NULL,
	[TipoStatusAge_id] [tinyint] NOT NULL,
	[tStatus] [int] NOT NULL,
	[fecha] [datetime] NOT NULL CONSTRAINT [DF_ccLogAgentesDia_fecha]  DEFAULT (getdate())
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [ccLogAgentesDia_fecAsc] ON [dbo].[ccLogAgentesDia] 
(
	[fecha] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [ccLogAgentesDia_userId] ON [dbo].[ccLogAgentesDia] 
(
	[User_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='CREATE NONCLUSTERED INDEX [ccLogAgentesDia_tipoAgeId] ON [dbo].[ccLogAgentesDia] 
(
	[TipoStatusAge_id] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[ccLogAgentesDia]  WITH CHECK ADD  CONSTRAINT [FK_ccLogAgentesDia_ccTipoStatusAgente] FOREIGN KEY([TipoStatusAge_id])
REFERENCES [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id])'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[ccLogAgentesDia] CHECK CONSTRAINT [FK_ccLogAgentesDia_ccTipoStatusAgente]'
	EXEC(@Sql)

	 set @Sql='CREATE PROCEDURE [dbo].[ccspGenAgentStatusSepHour]
@start_date	datetime,
@end_date	datetime
AS
BEGIN
	DECLARE @user_id smallint,
		@status_id	tinyint,
		@duracion	int,
		@timetot	int,
		@end_time	datetime,
		@start_time	datetime,
		@base_hour	datetime,
		@duracion_rest	int,
		@sql as varchar (8000),
		@full_hours	int,
		@cur_hour	int

	DECLARE Log_Cursor CURSOR FOR
	SELECT [user_id], tipostatusage_id, tstatus, fecha
		, DATEADD(s, -tstatus, fecha) AS start
		FROM ccLogAgentesDia 
		WHERE  fecha > DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), DATEADD(ss, -tstatus, fecha), 121) + '':00'', 121))
			AND fecha between @start_date and @end_date
		ORDER BY fecha
	
	OPEN Log_Cursor
	FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time

	WHILE @@fetch_status = 0 
	BEGIN
		SELECT @base_hour = DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), @start_time, 121) + '':00'', 121))
		SELECT @duracion_rest = DATEDIFF(s, @base_hour, @end_time)
		SELECT @full_hours = @duracion_rest / 3600
		select @timetot = @duracion
	
		set @sql = ''INSERT INTO ccLogAgentesDia ([user_id], tipostatusage_id, tstatus, fecha) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '','' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))+ '','' + char(0x27) + convert(varchar(20),@base_hour,120) + char(0x27) + '')''
		exec sp_sqlexec @sql

		select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
		SELECT @cur_hour = 1

		WHILE @cur_hour <= @full_hours
		BEGIN
			set @sql = ''INSERT INTO ccLogAgentesDia ([user_id], tipostatusage_id, tstatus, fecha) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '', 3600,'' + char(0x27) + convert(varchar(20),DATEADD(hh, @cur_hour, @base_hour),120) + char(0x27) + '')''
			exec sp_sqlexec @sql

			select @timetot = @timetot - 3600
			SELECT @cur_hour = @cur_hour + 1
		END

		--set @sql = ''UPDATE ccLogAgentesDia SET tstatus = ('' + convert(varchar(10),@duracion_rest) + '' % 3600) - 1 WHERE [user_id]='' + convert(varchar(5),@user_id) + '' AND tipostatusage_id='' + convert(varchar(5),@status_id) + '' AND fecha= '' + convert(varchar(20),@end_time) + ''''
		set @sql = ''UPDATE ccLogAgentesDia SET tstatus = ('' + convert(varchar(10),@timetot) + '' % 3600) WHERE [user_id]='' + convert(varchar(5),@user_id) + '' AND tipostatusage_id='' + convert(varchar(5),@status_id) + '' AND fecha= '' + char(0x27) + convert(varchar(24),@end_time,121) + char(0x27) + ''''

		exec sp_sqlexec @sql
		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
	END
	CLOSE Log_Cursor
	DEALLOCATE Log_Cursor
END
'
		EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenAgent]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenAgent WHERE timegroup>=@from AND timegroup<@to

INSERT INTO ccGenAgent(timegroup,[user_id],tlog,tnot_av,tav,tprob,tunknown,tother,nother,nMoh,nWHag,nWHcl)
SELECT timegroup,[user_id],tlog,tnot_av
	,CASE WHEN tav>=tprob AND tav>=tother AND tav>=tunknown THEN tav +(tlog - ttot)ELSE tav END AS tav
	,CASE WHEN tprob>tav AND tprob>tother AND tprob>tunknown THEN tprob +(tlog - ttot)ELSE tprob END AS tprob
	,CASE WHEN tunknown>tav AND tunknown>tother AND tunknown>tprob THEN tunknown +(tlog - ttot)ELSE tunknown END AS tunknown
	,CASE WHEN tother>tav AND tother>tprob AND tother>tunknown THEN tother +(tlog - ttot)ELSE tother END AS tother
	,nother,nMoh,nWHag,nWHcl
 FROM(
		SELECT xDetail.timegroup,xDetail.[user_id],(t1+t2+t3+t4)AS tlog,tnot_av,tav,tprob,tunknown,tother,nother
			,(tnot_av + tav + tprob + tother + tunknown + txfer + tdialog + tnotes + tring)AS ttot,nMoh,nWHag,nWHcl
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
		
				,ISNULL((SELECT top 1 DATEDIFF(s,xTimeDetail.timegroup,logout)
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<xTimeDetail.timegroup AND logout>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t1
				,ISNULL((SELECT top 1 3600
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login<=xTimeDetail.timegroup AND logout>DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t2
				,ISNULL((SELECT SUM(DATEDIFF(s,login,logout))
							 FROM ccGenSession
							 WHERE [user_id]=xTimeDetail.[user_id]
								AND login>xTimeDetail.timegroup AND logout<DATEADD(hh,1,xTimeDetail.timegroup)
					),0)AS t3
				,ISNULL((SELECT top 1 DATEDIFF(s,login,DATEADD(hh,1,xTimeDetail.timegroup))
							 FROM ccGenSession
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
					 FROM ccLogAgentesDia
					 WHERE DATEADD(ss,-tStatus,fecha)>=@from AND DATEADD(ss,-tStatus,fecha)<@to
					 GROUP BY CONVERT(smalldatetime,CONVERT(varchar(13),DATEADD(ss,-tStatus,fecha),121)+ '':00'',121),ccLogAgentesDia.[user_id]
				)xTimeDetail
					LEFT OUTER JOIN ccGenViewInCall ON(xTimeDetail.timegroup=ccGenViewInCall.timegroup AND xTimeDetail.[user_id]=ccGenViewInCall.[user_id])
					LEFT OUTER JOIN ccGenViewOutCall ON(xTimeDetail.timegroup=ccGenViewOutCall.timegroup AND xTimeDetail.[user_id]=ccGenViewOutCall.[user_id])
				GROUP BY xTimeDetail.timegroup,xTimeDetail.[user_id],tnot_av,tav,tprob,tother,nother,tunknown
		 	)xDetail
	)xAllTimes
 WHERE tlog>0
 ORDER BY timegroup,[user_id]'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenAgentStatusSepHourNotReady]
@start_date	datetime,
@end_date	datetime
AS
BEGIN
	DECLARE @user_id smallint,
		@status_id	tinyint,
		@duracion	int,
		@timetot	int,
		@end_time	datetime,
		@start_time	datetime,
		@base_hour	datetime,
		@sql as varchar (8000),
		@duracion_rest	int,
		@full_hours	int,
		@cur_hour	int

	DECLARE Log_Cursor CURSOR FOR
	SELECT [user_id], tiponotready_id, tstatus, fecha
		, DATEADD(s, -tstatus, fecha) AS start
		FROM ccLogAgentesNotReady 
		WHERE  fecha > DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), DATEADD(ss, -tstatus, fecha), 121) + '':00'', 121))
			AND fecha between @start_date and @end_date
		ORDER BY fecha
	
	OPEN Log_Cursor
	FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time

	WHILE @@fetch_status = 0 
	BEGIN
		SELECT @base_hour = DATEADD(hh, 1, CONVERT(datetime, CONVERT(varchar(13), @start_time, 121) + '':00'', 121))
		SELECT @duracion_rest = DATEDIFF(s, @base_hour, @end_time)
		SELECT @full_hours = @duracion_rest / 3600
		select @timetot = @duracion
	
		set @sql = ''INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES ('' + convert(varchar(5),@user_id) +  '','' + convert(varchar(5),@status_id) + '','' + convert(varchar(5),convert(int,DATEDIFF(s, @start_time, @base_hour)))+ '','' + char(0x27) + convert(varchar(20),@base_hour,120) + char(0x27) + '', 3)''
		exec sp_sqlexec @sql

		select @timetot = @timetot - DATEDIFF(s, @start_time, @base_hour)
		SELECT @cur_hour = 1
		
		WHILE @cur_hour <= @full_hours
		BEGIN
			set @sql = ''INSERT INTO ccLogAgentesNotReady ([user_id], tiponotready_id, tstatus, fecha, separado) VALUES ('' + convert(varchar(5),@user_id) + '','' + convert(varchar(5),@status_id) + '', 3600,'' + char(0x27) + convert(varchar(20),DATEADD(hh, @cur_hour, @base_hour),120) + char(0x27) + '', 2)''
			exec sp_sqlexec @sql

			select @timetot = @timetot - 3600
			SELECT @cur_hour = @cur_hour + 1
		END

		--print(''UPDATE ccLogAgentesNotReady SET tstatus = ('' + convert(varchar(10),@duracion_rest) + '' % 3600) - 1, separado = 1 WHERE [user_id]= '' + convert(varchar(5),@user_id) + '' AND tiponotready_id= '' + convert(varchar(5),@status_id) + '' AND fecha= '' + convert(varchar(20),@end_time,120) + '' AND separado =0'')
		set @sql = ''UPDATE ccLogAgentesNotReady SET tstatus = ('' + convert(varchar(10),@timetot) + '' % 3600), separado = 1 WHERE [user_id]= '' + convert(varchar(5),@user_id) + '' AND tiponotready_id= '' + convert(varchar(5),@status_id) + '' AND fecha= '' + char(0x27) + convert(varchar(24),@end_time,121) + char(0x27) + '' AND separado =0''
		exec sp_sqlexec @sql

		FETCH NEXT FROM Log_Cursor INTO @user_id, @status_id, @duracion, @end_time, @start_time
	END
	CLOSE Log_Cursor
	DEALLOCATE Log_Cursor
END
'
		EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenAgentStatusNotReady]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS

DELETE ccGenAgentNotReady WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenAgentNotReady (timegroup, [user_id], tiponotready_id, amount, [time], amountReal)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121) AS timegroup
	, [user_id], tiponotready_id
	, COUNT(tStatus), SUM(tStatus)
	, sum( case when separado in (0,3) then 1 else null end ) --amount Real
 FROM ccLogAgentesNotReady
 WHERE DATEADD(ss, -tStatus, fecha) >= @from AND  DATEADD(ss, -tStatus, fecha) < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), DATEADD(ss, -tStatus, fecha), 121) + '':00'', 121), [user_id], tiponotready_id
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInSpec]
@from AS smalldatetime,
@to AS smalldatetime
AS
-- Delete previous data in case of reprocess HLAS

DELETE ccGenInSpec WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInSpec (timegroup, inbound_id, pos_tot, pos_time, pos_efect)
	SELECT timegroup, ccInboundAgentes.inbound_id
		, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max -- pos_tot
		, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	 FROM ccGenAgent
		INNER JOIN ccInboundAgentes ON (ccGenAgent.[user_id] = ccInboundAgentes.[user_id])
	 WHERE timegroup >= @from AND timegroup < @to  AND INBOUND_ID > 0
	 GROUP BY timegroup, ccInboundAgentes.inbound_id'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInAbnd]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
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
				, (CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END) AS abnd 
				, (cal_twait + cal_txfer + cal_tring) AS tAbnd
			 FROM ccCallsIn
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls
	WHERE (abnd IS NOT NULL) 
	 GROUP BY timegroup, inbound_id
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInAnsw]
@from AS smalldatetime,
@to AS smalldatetime
AS
DECLARE @tresDialog AS smallint

EXEC @tresDialog = ccspConfigTresDialog

-- Delete previous data in case of reprocess HLAS
DELETE ccGenInAnsw WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInAnsw (timegroup, inbound_id, amount, time_max, time_tot, [<10], [<20], [<30], [<40], [<50], [<60], [<120], [<180], [<240], [<300], [+300])
	SELECT timegroup
		, inbound_id
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
				, inbound_id
				, statuscall_id
				, (CASE WHEN ((statuscall_id = 13) AND (cal_tdialog  > @tresDialog)) THEN 1 ELSE NULL END) AS answer
				, (cal_twait + cal_txfer + cal_tring) AS tAnsw
			 FROM ccCallsIn
				WHERE cal_inicio >= @from AND  cal_inicio < @to
				AND INBOUND_ID > 0
		) xCalls
	 WHERE (answer IS NOT NULL)
	 GROUP BY timegroup, inbound_id
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInCalif]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
DELETE ccGenInCalif WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenInCalif (timegroup, inbound_id, [user_id], calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, inbound_id, [user_id], calif_id
	, COUNT(cal_inicio)
 FROM ccCallsIN
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 --and cal_tdialog > @tresDialog
AND INBOUND_ID > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), inbound_id, [user_id], calif_id
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCamp]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCamp WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCamp (timegroup, cam_id, pos_tot, pos_time, pos_efect)
	SELECT timegroup, ccCampsAgente.cam_id
		, COUNT(DISTINCT ccGenAgent.[user_id]) AS pos_max
		, SUM(tlog - (tnot_av + tprob + tother)) AS pos_time
		, COUNT(CASE WHEN (tlog - (tnot_av + tprob + tother)) > 2000 THEN 1 ELSE NULL END) AS tresPos
	 FROM ccGenAgent
		INNER JOIN ccCampsAgente ON (ccGenAgent.[user_id] = ccCampsAgente.[user_id])
	 WHERE timegroup >= @from AND timegroup < @to
	 GROUP BY timegroup, ccCampsAgente.cam_id
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCallCalif]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCallCalif WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallCalif (timegroup, cam_id, [user_id], calif_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cam_id, [user_id], calif_id
	, COUNT(*)
 FROM ccoCallsOut
 WHERE cal_inicio >= @from AND  cal_inicio < @to
 AND statuscall_id = 13 -- and cal_tdialog > @tresDialog AND cam_id > 0
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], calif_id
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCallDials]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCallDials WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCallDials (timegroup, cam_id, [puerto], tiporesdial_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121) AS timegroup
	, cam_id, puerto, tiporesdial_id
	, COUNT(*)
 FROM ccologdials
 WHERE fecha >= @from AND  fecha < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + '':00'', 121), cam_id, [puerto], tiporesdial_id
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccoDialers](
	[dialer_id] [int] IDENTITY(1,1) NOT NULL,
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

	set @Sql='ALTER TABLE [dbo].[ccoDialers]  WITH CHECK ADD  CONSTRAINT [FK_ccoDialers_cstoProvedor] FOREIGN KEY([provedor_id])
REFERENCES [dbo].[cstoProvedor] ([provedor_id])'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[ccoDialers] CHECK CONSTRAINT [FK_ccoDialers_cstoProvedor]'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[cstoTarifa](
	[provedor_id] [smallint] NOT NULL,
	[tipoLlamada_id] [smallint] NOT NULL,
	[minutoUno] [decimal](15, 3) NOT NULL CONSTRAINT [DF_cstoTarifa_minutoUno]  DEFAULT (0),
	[minutoAdicional] [decimal](15, 3) NOT NULL CONSTRAINT [DF_cstoTarifa_minutoAdicional]  DEFAULT (0),
 CONSTRAINT [PK_cstoTarifa] PRIMARY KEY CLUSTERED 
(
	[provedor_id] ASC,
	[tipoLlamada_id] ASC
) ON [PRIMARY]
) ON [PRIMARY]'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[cstoTarifa]  WITH CHECK ADD  CONSTRAINT [FK_cstoTarifa_cstoProvedor] FOREIGN KEY([provedor_id])
REFERENCES [dbo].[cstoProvedor] ([provedor_id])'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[cstoTarifa] CHECK CONSTRAINT [FK_cstoTarifa_cstoProvedor]'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[cstoTarifa]  WITH CHECK ADD  CONSTRAINT [FK_cstoTarifa_cstoTipoLlamada] FOREIGN KEY([tipoLlamada_id])
REFERENCES [dbo].[cstoTipoLlamada] ([tipoLlamada_id])'
	EXEC(@Sql)

	set @Sql='ALTER TABLE [dbo].[cstoTarifa] CHECK CONSTRAINT [FK_cstoTarifa_cstoTipoLlamada]'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutCstoResumen]
@from AS smalldatetime,
@to AS smalldatetime
AS

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to

INSERT INTO ccGenOutCstoResumen (timegroup, cam_id, [user_id], provedor_id, tipoLlamada_id, amount, mins, costo)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121) AS timegroup
	, cam_id, [user_id], provedor_id, tipoLlamada_id 
	, COUNT(*)
	, SUM( mins)
	, SUM( costo )
FROM
(
	SELECT cal_inicio, cam_id, [user_id], provedor_id, tipoLlamada_id, CEILING((cal_tXfer + cal_tRing + cal_tDialog +1 ) / 60.0 ) as mins, costo
	FROM ccoCallsOut
	WHERE cal_inicio >= @from AND  cal_inicio < @to and provedor_id is not null and cal_manual in (0,2)

	-- Tambien las llamdas que fueron fax
	UNION ALL

	SELECT cco.fecha as fecha, cco.cam_id, 0, p.provedor_id, l.tipoLlamada_id, 1, t.MinutoUno as costo
	FROM ccoLogDials cco, ccoDialers cd, cstoProvedor p, cstoTarifa t, cstoTipoLlamada l
	WHERE 
	cco.answerbit = 1 and cco.tiporesdial_id <> 1
	and cco.fecha >=  @from AND cco.fecha < @to
	and cco.puerto = cd.puerto
	and cd.provedor_id = p.provedor_id	
	and p.provedor_id = t.provedor_id
	and l.longitud = len(cco.telefono)
	and t.tipoLlamada_id = l.tipoLlamada_id
)x
GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), cal_inicio, 121) + '':00'', 121), cam_id, [user_id], provedor_id, tipoLlamada_id
'
	EXEC(@Sql)

		set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''cclogAgentesDia'',
''declare @server varchar(200) 
declare @sql varchar(8000) 
declare @from datetime 
declare @to datetime 
select @server = valor from ccsettings where setting_id = 22 
set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121) 
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121) 
set @sql = ''''declare @fec as varchar(20) 
select @fec = convert(varchar(20),isnull(convert(datetime,convert(varchar(20),dateadd(ss,1,max(fecha)),120),120),getdate()-1),120) from '''' + @server +''''.dbo.ccLogAgentesDia WITH(NOLOCK) ''''
set @sql = @sql + ''''SELECT User_id, TipoStatusAge_id, tStatus, fecha FROM ccLogAgentesDia WITH(NOLOCK) WHERE fecha >= @fec AND fecha < '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) 
--print @sql 
exec(@sql) 
exec ccsp_LogInfo @sql, -19'',''ccLogAgentesDia'',1,0,10,''01/01/1900 06:40'',''01/01/1900 23:40'',''1111111'','''','''','''','''','''','''',0,'''','''',1,1)'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[A_ccHistorico]
@fechaini as smalldatetime,
@fechafin as smalldatetime,
@credito as varchar(50),
@iduser as int =0,	--id de usuario
@camps as varchar(1000)=''''
 AS

DECLARE @sql varchar(8000)
DECLARE @tnombre varchar(50)
declare @dif as int

SET NOCOUNT ON 

set @camps = replace(@camps,''@'',char(0x27))

select @dif = datediff(dd,@fechaini,@fechafin)

IF (@dif > 30)
BEGIN
	SELECT @fechafin = DATEADD(d, 30,@fechaini)
END

set @iduser = 2
set @tnombre = ''TempHistorico''
select * from dbo.sysobjects where id = object_id(N''[dbo].[''+@tnombre+'']'')

if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[''+@tnombre+'']'') )
BEGIN
    set @sql =''drop table dbo.''+@tnombre
   exec(@sql)
END

set @sql = ''CREATE TABLE dbo.''+@tnombre +''( callout_id varchar(20), cal_key varchar(20), cal_id varchar(20), cam_id int, tiporesDial_id int, telefono varchar(20), fecha smalldatetime, userid int, calif_id int, tdialog int, cal_fcallback smalldatetime,cal_puerto int, grab_id varchar(20), cal_telCallBack varchar(15))''

--print @sql
exec (@sql)
set @sql = ''''

set @sql = '' INSERT INTO ''+@tnombre +'' (cal_id, tiporesdial_id, telefono, fecha, userid, calif_id, tdialog, cal_fcallback, cal_puerto, cam_id, cal_key, callout_id, grab_id,cal_telCallBack)
select cco.cal_id,cld.tipoResDial_id, cld.Telefono, cld.fecha, cco.user_id, cco.calif_id, cco.cal_tdialog, cco.cal_fcallback,cco.cal_puerto, cld.cam_id, cld.cal_key,cld.callout_id, 
(select grab.grab_id from ccrecorderv2.dbo.TREC_GRABACION grab where grab.info1 = cco.cal_id and grab.finicio between dateadd(mi,-10, cld.fecha) and dateadd(mi,1, cld.fecha) and grab.puerto_id = cco.cal_puerto) 
as grab_id, cco.cal_telCallBack
from (
select cld.*,cosr.CAL_KEY  from ccoCallsOutSource cosr right join ccologdials cld on (cld.cam_id = cosr.cam_id and cld.callout_id = cosr.callout_id )
 where cosr.CAL_KEY =  '' + @credito + ''''

if @camps <> '''' 
begin
set @sql = @sql + '' and cosr.cam_id in ('' + @camps + '') ''
end


set @sql = @sql + '' ) cld
 left join ccocallsout cco on ( cld.callout_id = cco.callout_id and cld.cam_id = cco.cam_id AND cco.cal_Inicio BETWEEN DATEADD(n,-1,cld.Fecha) AND DATEADD(n,1,cld.Fecha)
and cld.fecha>=dateadd(mm,-1,getdate()) ) ''

--print @sql
exec (@sql)
set @sql = ''''

    
SELECT hist.cal_Key AS CUENTA,  hist.Telefono AS TELEFONO, ISNULL(trd.descripcion, ''SIN RESULTADO'') AS RESULTADO, CASE WHEN hist.cam_id = 0 THEN ''SIN CAMPAA'' WHEN hist.cam_id IS NULL THEN ''NO CAMPAA'' ELSE cam.cam_descripcion END AS CAMPAA, CONVERT(varchar(10),hist.fecha,103)+'' ''+CONVERT(varchar(5),hist.fecha,108) AS FECHA,  CASE  WHEN hist.calif_id = 0 THEN ''SIN CALIFICAR''  WHEN hist.calif_id IS NULL THEN ''NO CALIFICADO'' ELSE tcl.[Description] END AS CALIFICACION,
 ISNULL(usr.Login, '''') AS LOGIN,  ISNULL(hist.tDialog,'''') AS TDIALOG, CASE WHEN  hist.cal_fcallback IS NULL THEN ''SIN REPROGRAMAR'' ELSE CONVERT(varchar(10),hist.cal_fcallback,103)+'' ''+  CONVERT(varchar(5),hist.cal_fcallback,108)  END AS REPROGRAMACION, ISNULL(usr.Nombres,'''') + '' '' + ISNULL(usr.ApellidoPaterno, '''') + '' '' + ISNULL(usr.ApellidoMaterno, '''') AS USUARIO, CASE WHEN hist.grab_id IS NULL THEN ''SIN GRABACION'' ELSE CONVERT(varchar(11), hist.grab_id) END as GRABACION, hist.cal_telCallBack as Tel_callback from 
 (select * from TempHistorico hist where fecha BETWEEN @fechaini AND @fechafin) as hist
 LEFT OUTER JOIN ccTipoResultadoDial trd  ON hist.tipoResDial_id = trd.tipoResDial_id LEFT OUTER JOIN ccCamps cam ON hist.cam_id = cam.cam_id LEFT OUTER JOIN ccTipoCalifOUT tcl  ON hist.calif_id = tcl.calif_id LEFT OUTER JOIN ccUsers usr  ON hist.Userid = usr.User_id
 AND hist.cam_id in ( select cam_id from ccSupervisorCam where tipo=1 and user_id= 2) 
 AND hist.cal_key = @credito ORDER BY hist.fecha

  set @sql =''drop table dbo.''+@tnombre
  exec(@sql)
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccsp_LogInfo] 
@sLogInfo varchar(100),
@iParentInfo smallint = 0
AS

insert ccLogInfo values (getdate(), @sLogInfo, @iParentInfo)
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenABorraAntiguo]
@from AS smalldatetime,
@to AS smalldatetime
AS

DELETE ccGenAgent WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenAgentNotReady WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInAbnd WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInAnsw WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInCalif WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInCall WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenInSpec WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCall WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCallCalif WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCallDials WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCamp WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenOutCstoResumen WHERE timegroup >= @from AND timegroup < @to
DELETE ccGenSession where login >= @from and login < @to
DELETE ccGenResumenAgente WHERE fecha >= @from AND fecha < @to
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenInCDN]
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
					, COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END) AS nabnd, COUNT(CASE WHEN (statuscall_id = 4) THEN 1 ELSE NULL END) AS nno_agent, COUNT(CASE WHEN (statuscall_id = 7) THEN 1 ELSE NULL END) AS ntimeout
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

	set @Sql='CREATE PROCEDURE [dbo].[ccspGenOutMarcCalif]
@from AS varchar(20),
@to AS varchar(20),
@server as varchar(100)
AS

declare @sql varchar(8000)

-- Delete previous data in case of reprocess HLAS
DELETE ccGenOutMarcCalif WHERE timegroup >= @from AND timegroup < @to

set @sql = ''INSERT INTO ccGenOutMarcCalif (timegroup, cam_id, tiporesdial_id, amount)
SELECT CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + ''+char(0x27)+'':00''+char(0x27)+'', 121) AS timegroup
	, cam_id, tiporesdial_id
	, COUNT(*)
 FROM ccoLogDials
 WHERE fecha >= @from AND  fecha < @to
 GROUP BY CONVERT(smalldatetime, CONVERT(varchar(13), fecha, 121) + ''+char(0x27)+'':00''+char(0x27)+'', 121), cam_id, tiporesdial_id''
--print (@sql)
exec (@sql)
'
	EXEC(@Sql)

	set @Sql='alter table ccDNIS alter column dni_numero varchar(50)'
	EXEC(@Sql)

	set @Sql='update exp_jobs set useCCenInCNX = 0 where job_id > 5 and useCCenInCNX = 1'
	EXEC(@Sql)

	set @Sql='ALTER TABLE dbo.ccoCallsOutSource ADD
	cal_telefono varchar(19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono]  DEFAULT (''''),
	cal_telefono2 varchar(19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono2]  DEFAULT (''''),
	cal_telefono3 varchar(19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono3]  DEFAULT (''''),
	cal_telefono4 varchar(19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono4]  DEFAULT (''''),
	cal_telefono5 varchar(19) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_cal_telefono5]  DEFAULT (''''),
	[Dato1] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato1]  DEFAULT (''''),
	[Dato2] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato2]  DEFAULT (''''),
	[Dato3] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato3]  DEFAULT (''''),
	[Dato4] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato4]  DEFAULT (''''),
	[Dato5] [varchar](255) NOT NULL CONSTRAINT [DF_ccoCallsOutSource_Dato5]  DEFAULT ('''')
'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] ([Dato1]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] ([Dato3]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] ([cal_telefono]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] ([cal_telefono2]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] ([cal_telefono3]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] ([cal_telefono4]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='CREATE INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] ([cal_telefono5]) WITH (FILLFACTOR = 90) ON [PRIMARY];'
	EXEC(@Sql)

	set @Sql='update exp_jobs set readquery = ''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @fec1 as varchar(20)
select @fec1 = max(callout_id) from '''' + @server +''''.dbo.ccocallsoutsource WITH(NOLOCK)
''''
set @sql = @sql + ''''select callout_id,cal_key,cam_id,cal_fechaDial, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, Dato1, Dato2, Dato3, Dato4, Dato5 from ccoCallsOutSource WITH(NOLOCK) where callout_id > @fec1 AND cal_fechadial < '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27)
--print @sql
exec(@sql)

exec ccsp_LogInfo @sql, -19'' where job_id = 6'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_agentes]
@from datetime,
@to datetime
AS

BEGIN

SELECT acd.user_id [user],agt_name [Nombre Agente],
isnull(nacd,0) [Llamadas ACD],
tprom_acd [Tiempo prom ACD],
tprom_acw [Tiempo prom ACW],
t_acd [Tiempo ACD],
t_acw [Tiempo ACW],
tresp [Tiempo Llamado Agente], 
t_otra [Otra Hora],
t_aux [Tiempo AUX],
t_disp [Tiempo Disponible],
t_pers [Tiempo Personal],
cayuda [Ayuda], xfersal [Trans Salida] 
FROM
	(select
		c.user_id,
		count(case when c.statusCall_id=13 then 1 else null end) nacd,
		substring(convert(varchar,dateadd(ss,isnull(avg(case when c.statusCall_id=13 then c.cal_tdialog else null end),0),''''),120),12,8) tprom_acd,
		substring(convert(varchar,dateadd(ss,isnull(avg(case when c.statusCall_id=13 then c.cal_tnotas else null end),0),''''),120),12,8) tprom_acw,
		substring(convert(varchar,dateadd(ss,sum(case when c.statusCall_id=13 then c.cal_tdialog else 0 end),''''),120),12,8) t_acd,
		substring(convert(varchar,dateadd(ss,sum(c.cal_tnotas),''''),120),12,8) t_acw,
		substring(convert(varchar,dateadd(ss,sum(case when c.statuscall_id = 13 then (c.cal_twait + c.cal_txfer + c.cal_tring) else NULL end),''''),120),12,8) tresp,
		count(case when l.modo in (3,4) and l.tipo=1 then 1 else NULL end) cayuda, 
		count(case when l.modo in (0,3,4) and l.tipo=1 then 1 else NULL end) xfersal
	from cccallsin c (nolock) 
	LEFT OUTER JOIN ccLogTransfers l (nolock) on (l.cal_id = c.cal_id and l.fechaFin between @from and @to)
	where c.cal_inicio between @from and @to and c.user_id>0 and c.inbound_id>0 group by c.user_id) acd
LEFT OUTER JOIN
	(select user_id,
	substring(convert(varchar,dateadd(ss,sum(case when TipoStatusAge_id in (5,6,7) then tstatus else 0 end),''''),120),12,8) t_otra,
	substring(convert(varchar,dateadd(ss,sum(case when TipoStatusAge_id = 2 then tstatus else 0 end),''''),120),12,8) t_aux, 	
	substring(convert(varchar,dateadd(ss,sum(case when TipoStatusAge_id = 3 then tstatus else 0 end),''''),120),12,8) t_disp, 
	substring(convert(varchar,dateadd(ss,sum(tstatus),''''),120),12,8) t_pers
	from cclogagentesdia (nolock) where fecha between @from and @to group by user_id) tready
ON tready.user_id=acd.user_id
LEFT OUTER JOIN
	(select user_id,isnull(apellidopaterno,'''')+'' ''+isnull(apellidomaterno,'''')+'' ''+isnull(nombres,'''') agt_name
	from ccusers (nolock)) users
ON users.user_id=acd.user_id

END
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_diario]
@inb smallint,
@from datetime,
@to datetime
AS

BEGIN

SELECT
c.fecha [Dia],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tresp)/sum(c.nacd) else 0 end),''''),120),15,5) [Vel prom Resp],
substring(convert(varchar,dateadd(ss,(case when sum(c.nabnd)>0 then sum(c.tabnd)/sum(c.nabnd) else 0 end),''''),120),15,5) [Tiempo prom Abandono],
isnull(sum(c.nacd),0) [Llamadas ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end),''''),120),15,5) [Tiempo prom ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacw)/sum(c.nacd) else 0 end),''''),120),15,5) [Tiempo prom ACW],
isnull(sum(c.nabnd),0) [Llamadas Aband],
substring(convert(varchar,dateadd(ss,max(c.maxdem),''''),120),15,5) [Demora Maxima],
isnull(sum(l.fent),0) [Flujo Entrada],
isnull(sum(l.fsal),0) [Flujo Salida],
isnull(sum(l.SalExt),0) [Llamadas Salida Ext],
substring(convert(varchar,dateadd(ss,(case when sum(l.SalExt)>0 then sum(l.tprosalext)/sum(l.SalExt) else 0 end),''''),120),15,5) [TProm Salida Ext],
isnull(sum(c.ncalque),0) [Llamadas Elim Cola],
substring(convert(varchar,dateadd(ss,(case when sum(c.ncalque)>0 then sum(c.tcalque)/sum(c.ncalque) else 0 end),''''),120),15,5) [TProm Elim Cola],
isnull(case when sum(g.tses)>0 then convert(decimal(15,2),(convert(float,sum(c.tacd))+ convert(float,sum(c.tacw)))*100 / convert(float,sum(g.tses))) else 0 end,0) [% Tiempo ACD],
isnull(case when (sum(c.nacd)+sum(c.nabnd))>0 then convert(decimal(15,2),convert(float,sum(c.nacd))*100/(convert(float,sum(c.nacd))+convert(float,sum(c.nabnd)))) else 0 end,0) [% Llamadas Resp]
FROM
	(SELECT 
	substring(convert(varchar,cal_inicio,121),1,10) fecha,	
	count(i.cal_id) ncalls, 
	count(case when i.statusCall_id=13 then 1 else null end) nacd,
	sum(case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else NULL end) as tresp,
	sum(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) AS tAbnd,
	sum(case when i.statusCall_id=13 then i.cal_tdialog else null end) tacd,
	sum(case when i.statusCall_id=13 then i.cal_tnotas else null end) tacw,
	--count(case when (i.statuscall_id IN (5,6) nabnd, --AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else null end) nabnd,
	count(case when (i.statuscall_id IN (5,6)) then 1 else null end) nabnd, --AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else null end) nabnd,
	max(case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) maxdem,
	count(case when (i.statuscall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else NULL end) ncalque, --(Tiempo de Desborde)
	sum(case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then i.cal_tWait else null end) tcalque,
	(select count(distinct inbound_id) from cccallsin (nolock) where cal_inicio between @from and @to) nesp
	from cccallsin i (nolock)
	where i.inbound_id=@inb and i.cal_inicio between @from and @to
	GROUP BY 
	substring(convert(varchar,cal_inicio,121),1,10)) C
LEFT OUTER JOIN
	(select substring(convert(varchar,fechafin,121),1,10) fecha,
			COUNT(CASE WHEN (t.modo =2) or (t.modo =5 and tipo=2) then 1 else NULL end) as fent,
			COUNT(CASE WHEN t.modo =2 and t.tipo=1 then 1 else NULL end) as fsal,
			COUNT(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else NULL end) as SalExt,-- Considerar el modo 5 para fuera de horario, servicio o especialidad por default
			SUM(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else NULL end) as tprosalext
	from ccLogTransfers t (nolock)-- indexar tabla y agregar la fecha de cclogtransfers
		inner join ccCallsIn i (nolock) on (i.cal_id = t.cal_id and i.inbound_id=@inb and i.cal_inicio between @from and @to)
	where t.fechafin between @from and @to
	group by substring(convert(varchar,fechafin,121),1,10)) l
		on L.fecha = c.fecha
LEFT OUTER JOIN
	(SELECT substring(convert(varchar,fecha,121),1,10) fecha,
		sum(t.tStatus) tses
	from  cclogagentesdia t with (index(IX_ccLogAgentesDia_1),nolock)
	where t.fecha between @from and @to and user_id in 
		(select distinct user_id from cccallsin where inbound_id=@inb and cal_inicio between @from and @to)
	group by substring(convert(varchar,fecha,121),1,10)) g
	on g.fecha = c.fecha
group by c.fecha  order by c.fecha

END
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_intervalos]
@inb smallint,
@from datetime
AS

declare @to datetime
select @to=convert(varchar(10),dateadd(dd,1,@from),121)

BEGIN

SELECT
convert(varchar(10),fecha,121) [Dia],
c.rango1 [Rango1],
c.rango2 [Rango2],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tresp)/sum(c.nacd) else 0 end),''''),120),15,5) [Vel prom Resp],
substring(convert(varchar,dateadd(ss,(case when sum(c.nabnd)>0 then sum(c.tabnd)/sum(c.nabnd) else 0 end),''''),120),15,5) [Tiempo prom Abandono],
isnull(sum(c.nacd),0) [Llamadas ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end),''''),120),15,5) [Tiempo prom ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacw)/sum(c.nacd) else 0 end),''''),120),15,5) [Tiempo prom ACW],
isnull(sum(c.nabnd),0) [Llamadas Aband],
substring(convert(varchar,dateadd(ss,max(c.maxdem),''''),120),15,5) [Demora Maxima],
isnull(sum(l.fent),0) [Flujo Entrada],
isnull(sum(l.fsal),0) [Flujo Salida],
isnull(sum(l.SalExt),0) [Llamadas Salida Ext],
substring(convert(varchar,dateadd(ss,(case when sum(l.SalExt)>0 then sum(l.tprosalext)/sum(l.SalExt) else 0 end),''''),120),15,5) [TProm Salida Ext],
isnull(sum(c.ncalque),0) [Llamadas Elim Cola],
substring(convert(varchar,dateadd(ss,(case when sum(c.ncalque)>0 then sum(c.tcalque)/sum(c.ncalque) else 0 end),''''),120),15,5) [TProm Elim Cola],
isnull(case when sum(g.tses)>0 then convert(decimal(15,2),(convert(float,sum(c.tacd))+ convert(float,sum(c.tacw)))*100 / convert(float,sum(g.tses))) else 0 end,0) [% Tiempo ACD],
isnull(case when (sum(c.nacd)+sum(c.nabnd))>0 then convert(decimal(15,2),convert(float,sum(c.nacd))*100/(convert(float,sum(c.nacd))+convert(float,sum(c.nabnd)))) else 0 end,0) [% Llamadas Resp],
isnull(case when sum(c.nesp)>0 then sum(g.tnot)/(sum(c.nesp)*1800) else 0 end,0)  [Prom. Posicion Personal],
isnull(sum(cc.ncalp),0)  [Llamadas por Posic.]
FROM
	(SELECT 
	CONVERT(datetime, CONVERT(varchar(4),YEAR(i.cal_inicio))+''-''+CONVERT(varchar(2), MONTH(i.cal_inicio))+''-''+CONVERT(varchar(2), DAY(i.cal_inicio))  + '' '' + 	case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end ,121) as FECHA,
	case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end as RANGO1,
	case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), i.cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(i.cal_inicio) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2),CONVERT(int, { fn HOUR(i.cal_inicio) })+1)+'':''+''00'' else CONVERT(varchar(2),CONVERT(int, { fn HOUR(i.cal_inicio) }))+'':''+''30'' end as RANGO2,
	count(i.cal_id) ncalls, 
	count(case when i.statusCall_id=13 then 1 else null end) nacd,
	sum(case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else NULL end) as tresp,
	sum(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) AS tAbnd,
	sum(case when i.statusCall_id=13 then i.cal_tdialog else null end) tacd,
	sum(case when i.statusCall_id=13 then i.cal_tnotas else null end) tacw,
	count(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else null end) nabnd,
	max(case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) maxdem,
	count(case when (i.statuscall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else NULL end) ncalque, --(Tiempo de Desborde)
	sum(case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then i.cal_tWait else null end) tcalque,
	(select count(distinct inbound_id) from cccallsin (nolock) where cal_inicio between @from and @to) nesp
	from cccallsin i (nolock)
	where i.inbound_id=@inb and i.cal_inicio between @from and @to
	GROUP BY 
	CONVERT(datetime,CONVERT(varchar(4),YEAR(cal_inicio))+''-''+CONVERT(varchar(2), MONTH(cal_inicio))+''-''+CONVERT(varchar(2), DAY(cal_inicio))  + '' '' +case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,121),
	case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,
	case when right(case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,2)=''30'' then CONVERT(varchar(2),CONVERT(int, { fn HOUR(cal_inicio) })+1)+'':''+''00'' else CONVERT(varchar(2),CONVERT(int, { fn HOUR(cal_inicio) }))+'':''+''30'' end	) C
LEFT OUTER JOIN
	(select case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fechaFin), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''30'' end as rango1,
			COUNT(CASE WHEN (t.modo =2) or (t.modo =5 and tipo=2) then 1 else NULL end) as fent,
			COUNT(CASE WHEN t.modo =2 and t.tipo=1 then 1 else NULL end) as fsal,
			COUNT(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else NULL end) as SalExt,-- Considerar el modo 5 para fuera de horario, servicio o especialidad por default
			SUM(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else NULL end) as tprosalext
	from ccLogTransfers t (nolock)-- indexar tabla y agregar la fecha de cclogtransfers
		inner join ccCallsIn i (nolock) on (i.cal_id = t.cal_id and i.inbound_id=@inb and i.cal_inicio between @from and @to)
	where t.fechafin between @from and @to
	group by i.inbound_id,case when CONVERT(int, SUBSTRING(CONVERT(char(30),t.fechaFin), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fechaFin) })+'':''+''30'' end) l
		on L.rango1 = c.rango1
LEFT OUTER JOIN
	(SELECT case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end rango1,
		sum(t.tStatus) tses, -- tiene un pequeño desfase
		sum(case when t.TipoStatusAge_id not in (2,7,11) then t.tStatus else 0 end) tnot
	from  cclogagentesdia t with (index(IX_ccLogAgentesDia_1),nolock)
	where t.fecha between @from and @to and user_id in 
		(select distinct user_id from cccallsin where inbound_id=@inb and cal_inicio between @from and @to)
	group by case when CONVERT(int, SUBSTRING(CONVERT(char(30), t.fecha), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(t.fecha) })+'':''+''30'' end) g
	on g.rango1 = c.rango1
LEFT OUTER JOIN
	(select f.rango1 rango1, sum(f.ncont)/COUNT(*) ncalp
	from
		(select 
			case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end as rango1,
			user_id uid,
			count(case when statusCall_id=13 then 1 else NULL end) ncont 
		from cccallsin (nolock) 
		where inbound_id = @inb and cal_inicio between @from and @to
		group by case when CONVERT(int, SUBSTRING(CONVERT(char(30), cal_inicio), 16, 2)) / 30=0 then CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''00'' else CONVERT(varchar(2), { fn HOUR(cal_inicio) })+'':''+''30'' end,user_id 
		having count(case when statusCall_id=13 then 1 else NULL end)>0) f
		group by f.rango1) cc 
	on cc.rango1 = c.rango1	
group by c.fecha,c.rango1,c.rango2  order by c.fecha
END
'
	EXEC(@Sql)

	set @Sql='CREATE PROCEDURE [dbo].[sp_mkt_mensual]
@inb smallint,
@from datetime,
@to datetime
AS

BEGIN

SELECT
c.fecha [Dia],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tresp)/sum(c.nacd) else 0 end),''''),120),15,5) [Vel prom Resp],
substring(convert(varchar,dateadd(ss,(case when sum(c.nabnd)>0 then sum(c.tabnd)/sum(c.nabnd) else 0 end),''''),120),15,5) [Tiempo prom Abandono],
isnull(sum(c.nacd),0) [Llamadas ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacd)/sum(c.nacd) else 0 end),''''),120),15,5) [Tiempo prom ACD],
substring(convert(varchar,dateadd(ss,(case when sum(c.nacd)>0 then sum(c.tacw)/sum(c.nacd) else 0 end),''''),120),15,5) [Tiempo prom ACW],
isnull(sum(c.nabnd),0) [Llamadas Aband],
substring(convert(varchar,dateadd(ss,max(c.maxdem),''''),120),15,5) [Demora Maxima],
isnull(sum(l.fent),0) [Flujo Entrada],
isnull(sum(l.fsal),0) [Flujo Salida],
isnull(sum(l.SalExt),0) [Llamadas Salida Ext],
substring(convert(varchar,dateadd(ss,(case when sum(l.SalExt)>0 then sum(l.tprosalext)/sum(l.SalExt) else 0 end),''''),120),15,5) [TProm Salida Ext],
isnull(sum(c.ncalque),0) [Llamadas Elim Cola],
substring(convert(varchar,dateadd(ss,(case when sum(c.ncalque)>0 then sum(c.tcalque)/sum(c.ncalque) else 0 end),''''),120),15,5) [TProm Elim Cola],
isnull(case when sum(g.tses)>0 then convert(decimal(15,2),(convert(float,sum(c.tacd))+ convert(float,sum(c.tacw)))*100 / convert(float,sum(g.tses))) else 0 end,0) [% Tiempo ACD],
isnull(case when (sum(c.nacd)+sum(c.nabnd))>0 then convert(decimal(15,2),convert(float,sum(c.nacd))*100/(convert(float,sum(c.nacd))+convert(float,sum(c.nabnd)))) else 0 end,0) [% Llamadas Resp]
FROM
	(SELECT 
	substring(convert(varchar,cal_inicio,121),1,7) fecha,	
	count(i.cal_id) ncalls, 
	count(case when i.statusCall_id=13 then 1 else null end) nacd,
	sum(case when i.statuscall_id = 13  then (i.cal_twait + i.cal_txfer + i.cal_tring) else NULL end) as tresp,
	sum(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) AS tAbnd,
	sum(case when i.statusCall_id=13 then i.cal_tdialog else null end) tacd,
	sum(case when i.statusCall_id=13 then i.cal_tnotas else null end) tacw,
	count(case when (i.statuscall_id IN (5,6) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else null end) nabnd,
	max(case when i.statuscall_id = 13 then (i.cal_twait + i.cal_txfer + i.cal_tring) else 0 end) maxdem,
	count(case when (i.statuscall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then 1 else NULL end) ncalque, --(Tiempo de Desborde)
	sum(case when (i.statusCall_id in (7,8) AND (i.cal_que > 0) AND (i.cal_xfer IS NULL)) then i.cal_tWait else null end) tcalque,
	(select count(distinct inbound_id) from cccallsin (nolock) where cal_inicio between @from and @to) nesp
	from cccallsin i (nolock)
	where i.inbound_id=@inb and i.cal_inicio between @from and @to
	GROUP BY 
	substring(convert(varchar,cal_inicio,121),1,7)) C
LEFT OUTER JOIN
	(select substring(convert(varchar,fechafin,121),1,7) fecha,
			COUNT(CASE WHEN (t.modo =2) or (t.modo =5 and tipo=2) then 1 else NULL end) as fent,
			COUNT(CASE WHEN t.modo =2 and t.tipo=1 then 1 else NULL end) as fsal,
			COUNT(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then 1 else NULL end) as SalExt,-- Considerar el modo 5 para fuera de horario, servicio o especialidad por default
			SUM(CASE WHEN t.modo in (0,3,4) and t.tipo=1 then (t.tAntesXfer + t.tDespuesXfer) else NULL end) as tprosalext
	from ccLogTransfers t (nolock)-- indexar tabla y agregar la fecha de cclogtransfers
		inner join ccCallsIn i (nolock) on (i.cal_id = t.cal_id and i.inbound_id=@inb and i.cal_inicio between @from and @to)
	where t.fechafin between @from and @to
	group by substring(convert(varchar,fechafin,121),1,7)) l
		on L.fecha = c.fecha
LEFT OUTER JOIN
	(SELECT substring(convert(varchar,fecha,121),1,7) fecha,
		sum(t.tStatus) tses
	from  cclogagentesdia t with (index(IX_ccLogAgentesDia_1),nolock)
	where t.fecha between @from and @to and user_id in 
		(select distinct user_id from cccallsin where inbound_id=@inb and cal_inicio between @from and @to)
	group by substring(convert(varchar,fecha,121),1,7)) g
	on g.fecha = c.fecha
group by c.fecha  order by c.fecha

END
'
	EXEC(@Sql)

	set @Sql='CREATE TABLE [dbo].[ccLogTransfers](
	[cal_id] [int] NOT NULL,
	[tipo] [tinyint] NOT NULL,
	[modo] [tinyint] NOT NULL,
	[destino] [varchar](50) NOT NULL,
	[tAntesXfer] [int] NOT NULL CONSTRAINT [DF_ccLogTransfers_tAntesXfer]  DEFAULT (0),
	[tDespuesXfer] [int] NOT NULL CONSTRAINT [DF_ccLogTransfers_tDespuesXfer]  DEFAULT (0),
	[fechaFin] [datetime] NOT NULL CONSTRAINT [DF_ccLogTransfers_fechaFin]  DEFAULT (getdate())
) ON [PRIMARY]
'
	EXEC(@Sql)

	set @Sql='EXEC dbo.sp_addextendedproperty @name=N''MS_Description'', @value=N'''' , @level0type=N''USER'',@level0name=N''dbo'', @level1type=N''TABLE'',@level1name=N''ccLogTransfers'', @level2type=N''COLUMN'',@level2name=N''tDespuesXfer''
'
	EXEC(@Sql)

	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''cclogtransfers'',''declare @server varchar(200)
declare @sql  varchar(8000)
declare @from datetime
declare @to datetime

select @server = valor from ccsettings where setting_id = 22

set @from = convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '''':00'''',121)
set @to = convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '''':00'''',121)

set @sql = ''''declare @calInii as varchar(15)
declare @calfini as varchar(15)
select @calInii = isnull(max(cal_id),1) from '''' + @server +''''.dbo.ccLogTransfers
select @calfini = min(cal_id) from (select isnull(min(cal_id),0) cal_id from ccLogTransfers where fechafin > '''' + char(0x27) +  convert(varchar(20),@to,120) + char(0x27) + '''' union all select max(cal_id) cal_id from ccLogTransfers) as a where cal_id <> 0
''''
set @sql = @sql + ''''SELECT cal_id, tipo, modo, destino, tAntesXfer, tDespuesXfer, fechaFin from ccLogTransfers WHERE cal_id > @calInii and cal_id<= @calfini''''
--print @sql
exec(@sql)
exec ccsp_LogInfo @sql, -19'',''cclogtransfers'',1,0,10,''01/01/1900 06:40'',''01/01/1900 23:40'',''111111'','''','''','''','''','''','''',0,'''','''',1,1)

'
	EXEC(@Sql)

	set @Sql='ALTER FUNCTION [dbo].[fGetHHmmSS] (@time decimal)  
RETURNS varchar(20)
AS  
BEGIN 

	DECLARE @horas varchar(5)
	DECLARE @min varchar(2)
	DECLARE @seg varchar(2)
	DECLARE @Tiempo varchar(20)
    DECLARE @Temp decimal
	declare @tmp2 decimal

             set @Temp =  CAST(@time AS DECIMAL(20,3)) % 3600.0
			 set @tmp2 = CAST((@time - @Temp) AS DECIMAL(20,3)) / 3600.0
			 set @horas = @tmp2
			 set @tmp2 = 0
             set @tmp2 = CAST(@Temp AS DECIMAL(20,3)) % 60.0
			 set @seg = @tmp2
			 set @tmp2 = 0
             set @tmp2 =  CAST((@Temp - @seg) AS DECIMAL(20,3)) / 60.0
			 set @min = @tmp2
			 set @tmp2 = 0

             set @Tiempo = case when convert(varchar(5),@horas) = 0 then ''00'' when convert(varchar(5),@horas) < 10 then ''0''+ convert(varchar(5),@horas) else convert(varchar(5),@horas) end + '':''+case when convert(varchar(2),@min) = 0 then ''00'' when convert(varchar(2),@min) < 10 then ''0''+convert(varchar(2),@min) else convert(varchar(2),@min) end + '':''+case when convert(varchar(2),@seg)  = 0 then ''00'' when convert(varchar(2),@seg)  < 10 then ''0''+convert(varchar(2),@seg) else convert(varchar(2),@seg)  end

	RETURN (@Tiempo)
END
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
go
