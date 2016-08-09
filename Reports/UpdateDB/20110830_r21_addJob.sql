/*
Autor: Armando Rodriguez
Fecha: 2011/08/30
Descripcion: se agrega nuevo job para actualizar las llamadas con estatus 5 y pasarlas al estatus final de la llamada.
Version requerida: 20
*/
set nocount on

declare @Version int, @Version_Actual int
---------------- VERSION ----------------
Set @Version = '21'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
---------------- inicio SCRIPT @Sql ----------------

 	set @Sql='Insert into Exp_Jobs (description,readquery,writequery,active,intervaltype,interval,starttime,endtime,days,dserver,ddatabase,dlogin,dpass,vars,cnxorigen,validate,cvalidate,qupdate,useCCenInCNX,useCCRepInDes)
values(''updatestatus5'',
''declare @sql varchar(1000), @server varchar(300)
select @server = valor from ccsettings where setting_id = 22

set @sql = ''''update rep set rep.statuscall_id = cw.statuscall_id from ccocallsout cw, '''' + @server + ''''.dbo.ccocallsout rep 
where cw.cal_id = rep.cal_id and rep.statuscall_id = 11 and cw.statuscall_id <> rep.statuscall_id ''''
exec(@sql)

set @sql = ''''update rep set rep.statuscall_id = cw.statuscall_id from cccallin cw, '''' + @server + ''''.dbo.cccallsin rep 
where cw.cal_id = rep.cal_id and rep.statuscall_id = 11 and cw.statuscall_id <> rep.statuscall_id ''''
exec(@sql)'',''*N/A*'',1,0,60,''01/01/1900 00:30'',''01/01/1900 23:45'',''1111111'','''','''','''','''','''','''',0,'''','''',1,0)'
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
right JOIN(SELECT timegroup,inbound_id,[user_id],ISNULL(SUM(cal_twait),0)AS tque,ISNULL(SUM(cal_txfer),0)AS txfer
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


