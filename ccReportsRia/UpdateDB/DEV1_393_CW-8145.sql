SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 118

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF 1=1 --@actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-8145 Delete DetailReports RepAgentGI-2010'
	set @sql = 'delete from DetailReports where id=2010 --Elimina el detalle del reporte RepAgentGI'
	EXEC(@sql)
	
	set @process = 'CW-8145 drop table tmpccLogAgentesDia'
	set @sql = 'IF EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpccLogAgentesDia'')
BEGIN
	drop table tmpccLogAgentesDia
END'
	EXEC(@sql)

	set @process = 'CW-8145 drop table tmpTimesInboundData'
	set @sql = 'IF EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpTimesInboundData'')
BEGIN
	drop table tmpTimesInboundData
END'
	EXEC(@sql)

	set @process = 'CW-8145 drop table tmpTimesOutboundData'
	set @sql = 'IF EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpTimesOutboundData'')
BEGIN
	drop table tmpTimesOutboundData
END'
	EXEC(@sql)

	set @process = 'CW-8145 Rename Table -> RepAgentGI RepAgentGI_VersionOld'
	set @sql = 'if not exists(select * from sys.tables where name=''RepAgentGI_VersionOld'') begin
	EXEC sp_rename ''RepAgentGI'', ''RepAgentGI_VersionOld'';
	--drop table RepAgentGI
	CREATE TABLE [dbo].[RepAgentGI](
	[date] [datetime] NOT NULL,
	[userId] [int] NOT NULL,
	[user] [varchar](255) NOT NULL,
	[login] [varchar](40) NOT NULL,
	
	[tlog] [int] NOT NULL,
	[tunknown] [int] NOT NULL,
	[tav] [int] NOT NULL,
	[tnotav] [int] NOT NULL,
	[tother] [int] NOT NULL,
	[tprob] [int] NOT NULL,
	[tChatting] [int] NULL,
	[tundefined] [int] NULL,

	[nxferin] [int] NOT NULL,
	[nanswerin] [int] NOT NULL,
	[nabndxferin] [int] NOT NULL,
	[nabndringin] [int] NOT NULL,
	[nabnddlgin] [int] NOT NULL,
	[abndaxferin] [int] NOT NULL,
	[nnoanswerin] [int] NOT NULL,
	[nlostin] [int] NOT NULL,
	[tdialogin] [int] NOT NULL,
	[tnotesin] [int] NOT NULL,
	[tringin] [int] NOT NULL,
	[txferin] [int] NOT NULL,
	[nxferout] [int] NOT NULL,
	[nanswerout] [int] NOT NULL,
	[nabndxferout] [int] NOT NULL,
	[nabndringout] [int] NOT NULL,
	[nabnddlgout] [int] NOT NULL,
	[abndaxferout] [int] NOT NULL,
	[nnoanswerout] [int] NOT NULL,
	[nlostout] [int] NOT NULL,
	[tdialogout] [int] NOT NULL,
	[tnotesout] [int] NOT NULL,
	[tringout] [int] NOT NULL,
	[txferout] [int] NOT NULL,
	[nother] [int] NOT NULL,		
	[nmohin] [int] NOT NULL,
	[nmohout] [int] NOT NULL,
	[nwhagin] [int] NOT NULL,
	[nwhagout] [int] NOT NULL,
	[nwhcliin] [int] NOT NULL,
	[nwhcliout] [int] NOT NULL,		
	
	[year] [int] NOT NULL,
	[month] [int] NOT NULL,
	[day] [int] NOT NULL,
	[hour] [int] NOT NULL,
	[minutes] [int] NOT NULL,
	[tManual] [int] not NULL
)
end
else begin
	if not exists (select * from sys.columns where name = N''tManual'' and Object_ID = Object_ID(N''RepAgentGI''))
    begin
		ALTER TABLE RepAgentGI ADD [tManual] [int] NULL;        
    end	
end
'
	EXEC(@sql)

	set @process = 'CW-8145 Rename Table -> RepAgentGI RepAgentGI_VersionOld'
	set @sql = 'update RepAgentGI set [tManual]=0 where [tManual] is null'
	EXEC(@sql)

	set @process = 'CW-8145 CW-8145 sp_rename INDEX IX_RepAgentGI -> IX_RepAgentGI_VersionOld'
	set @sql = 'if  exists (select * from sys.indexes where name = N''IX_RepAgentGI'' and object_id = OBJECT_ID(N''RepAgentGI_VersionOld''))
begin
    EXEC sp_rename N''RepAgentGI_VersionOld.IX_RepAgentGI'', N''IX_RepAgentGI_VersionOld'', N''INDEX''; 
end
'
	EXEC(@sql)

	set @process = 'CW-8145 CREATE INDEX IX_RepAgentGI columns date,userId '
	set @sql = 'if not exists (select * from sys.indexes where name = N''IX_RepAgentGI'' and object_id = OBJECT_ID(N''RepAgentGI''))
begin
    CREATE NONCLUSTERED INDEX [IX_RepAgentGI] ON [dbo].[RepAgentGI]
	(
	[date] ASC,userId
	)
end'
	EXEC(@sql)

	set @process = 'CW-8145 CW-8145 DROP AND CREATE INDEX IX_RepAgentSession columns date,userId'
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentSession'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentSession ON RepAgentSession 

    CREATE NONCLUSTERED INDEX [IX_RepAgentSession] ON [dbo].[RepAgentSession] ([date] ASC,userId)
end'
	EXEC(@sql)


	set @process = 'CW-8145 CW-8145 DROP AND CREATE INDEX  IX_RepAgentSessionByInterval columns date,userId '
	set @sql = 'if exists (
select i.[name] as index_name    
from sys.objects t
inner join sys.indexes i on t.object_id = i.object_id
cross apply (
	select col.[name] + '', '' from sys.index_columns ic
	inner join sys.columns col on ic.object_id = col.object_id and ic.column_id = col.column_id
	where ic.object_id = t.object_id and ic.index_id = i.index_id
	order by key_ordinal for xml path ('''') 
	) D (column_names)
where t.is_ms_shipped <> 1
and index_id > 0
and t.[name] = ''RepAgentSessionByInterval'' and substring(column_names, 1, len(column_names)-1)=''date''
) begin
	DROP INDEX IX_RepAgentSessionByInterval ON RepAgentSessionByInterval 

    CREATE NONCLUSTERED INDEX [IX_RepAgentSessionByInterval] ON [dbo].[RepAgentSessionByInterval] ([date] ASC,userId)
end'
	EXEC(@sql)

	set @process = 'CW-8145 Alter Sp ReportsMasterProcessWIthOnlyGenerate'
	set @sql = 'ALTER PROCEDURE [dbo].[ReportsMasterProcessWIthOnlyGenerate] @from AS DATETIME = NULL
	,@to AS DATETIME = NULL
	,@scheduleTime INT = 10
	,@dateStart DATETIME = NULL
AS
SET ANSI_WARNINGS OFF
SET NOCOUNT ON

DECLARE @i INT,@count INT
DECLARE @SQL nVARCHAR(4000)
DECLARE @name SYSNAME
DECLARE @descError NVARCHAR(max)
DECLARE @dateSP DATETIME

IF @from IS NULL
BEGIN
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))
END

IF @to IS NULL
BEGIN
	SET @to = getdate()
END

IF @dateStart IS NULL
BEGIN
	SET @dateStart = getdate()
END

EXEC ccspTmpTimesInterval @from = @from	,@to = @to	,@interval = 15 --Tabla TmpTimesInterval Temporal para tener Intervalos de 15 Minutos
EXEC ccspTmpSessionGeneral @from = @from	,@to = @to				--Tabla tmpSessionGeneral para tener la sesiones de agentes
EXEC ccspTmpSessionTimeGroup @from = @from	,@to = @to				--Tabla tmpSessionTimeGroup para dividir la sesion en intervalos de 15 Minutos
EXEC ccspTimesccLogAgentesDia @from = @from	,@to = @to				--Tabla tmpccLogAgentesDia tener los movimientos de los agentes
EXEC ccspTimesOutboundData @from = @from	,@to = @to				--Tabla tmpTimesOutboundData para los tiempos de las llamadas de salida
EXEC ccspTimesInboundData @from = @from	,@to = @to					--Tabla tmpTimesInboundData para los tiempos de las llamadas de entrada
exec ccspTmpTimesccLogtransfers @from = @from, @to = @to			--Tabla TmpTimesccLogtransfers para los tiempos de las llamadas que son trasferidas
exec ccsptmpTimesHoldIn @from = @from, @to = @to					--Tabla tmpTimesHoldIn para los tiempos cuando se pone en hold en llamadas de entrada

CREATE TABLE #tmpProcedureReports (
	id INT
	,name SYSNAME
	)

declare @tableSpDontProcess table(nameSp varchar(300) primary key not null)

insert into @tableSpDontProcess values(''ccspRepCatalogos'') -- ccspRepCatalogos es para catalogos por eso no se debe correr
insert into @tableSpDontProcess values(''ccsprepLogAgentriaseparate'') -- ccsprepLogAgentriaseparate Separa en intervalos de 15 Minutos ccloAgentDia 
insert into @tableSpDontProcess values(''ccspRepAgentSession'') -- ccspRepAgentSession Genera el reporte de sesiones para alimentar  
-- insert into @tableSpDontProcess values(''ccspRepTrunkBusy'') -- ccspRepTrunkBusy Es necesario revisar si se ocupan estos reportes y encaso de procesar mucha informacion crear un job para que se ejecute cada 2 horas o algo por el estilo
insert into @tableSpDontProcess values(''ccspRepAgentNotReadyDet'') -- ccspRepAgentNotReadyDet sabemos cuando inicia y cuando termina los no disponibles 
insert into @tableSpDontProcess values(''ccspRepAgentNotReady'') -- ccspRepAgentNotReady Agrupa por hora
insert into @tableSpDontProcess values(''ccspRepAgentGI'') 		-- ccspRepAgentGI Agrupa por hora

INSERT INTO #tmpProcedureReports
SELECT ROW_NUMBER() OVER (
		ORDER BY [name]
		) AS id
	,[name]
FROM sys.procedures
WHERE [name] LIKE ''ccspRep%''
	AND [name] NOT IN (select nameSp from @tableSpDontProcess)
	AND name NOT IN (
		SELECT name
		FROM logsReportsMaster
		WHERE STATUS = 0
			AND dateStart >= @dateStart
		)

--1 Se saca este reporte primero para reutilizarlo en otros reportes que lo necesiten
exec ccspRepAgentSession @action=1,@from=@from,@to=@to --Saca el detalle de las sesiones
exec ccspRepAgentNotReadyDet @action=1,@from=@from,@to=@to --Saca el detalle de los no disponibles
exec ccspRepAgentNotReady @action=1,@from=@from,@to=@to --Agrupa a los no disponibles por hora
exec ccspRepAgentGI @action=1,@from=@from,@to=@to 	--Agrupa por 15 minutos

INSERT INTO [logsReportsMaster] (
	name
	,STATUS
	,dateStart
	,dateEnd
	,error
	,maxTime
	)
SELECT name
	,0
	,''19000101''
	,''19000101''
	,''''
	,@scheduleTime
FROM #tmpProcedureReports

SELECT @i = 1, @count = count(*) FROM #tmpProcedureReports

WHILE @i <= @count
	AND datediff(mi, @dateStart, getdate()) < @scheduleTime
BEGIN
	SELECT @name = name
	FROM #tmpProcedureReports
	WHERE id = @i

	SET @sql = ''EXEC '' + @name + '' @action=1, @from=@from, @to=@to''
	
	SET @dateSP = getdate()

	BEGIN TRY
		--print @sql
		
		exec sp_executesql @sql, N''@from DATETIME, @to DATETIME'',@from, @to  				

		IF (datediff(ss, @dateStart, getdate()) > @scheduleTime * 60)
		BEGIN
			UPDATE [logsReportsMaster]
			SET STATUS = 2
				,dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime + 1
				,error = ''Increment time shuduler '' + convert(VARCHAR(max), @scheduleTime)
			WHERE name = @name
				AND STATUS = 0
				AND dateStart = ''19000101''
				AND dateEnd = ''19000101''

			UPDATE [logsReportsMaster]
			SET dateStart = @dateSP
				,dateEnd = getdate()
				,maxTime = @scheduleTime
			WHERE STATUS = 0
				AND dateStart = ''19000101''
				AND dateEnd = ''19000101''

			BREAK
		END

		UPDATE [logsReportsMaster]
		SET STATUS = 1
			,dateStart = @dateSP
			,dateEnd = getdate()
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = ''19000101''
			AND dateEnd = ''19000101''
			
	END TRY

	BEGIN CATCH
		SELECT @descError = ''Line: '' + cast(error_line() AS NVARCHAR) + '' Number: '' + cast(@@error AS NVARCHAR) + '' Message: '' + error_message()

		SELECT @descError,@name

		UPDATE [logsReportsMaster]
		SET STATUS = 3
			,dateStart = @dateSP
			,dateEnd = getdate()
			,error = @descError
		WHERE name = @name
			AND STATUS = 0
			AND dateStart = ''19000101''
			AND dateEnd = ''19000101''
	END CATCH

	SET @i = @i + 1
END

DROP TABLE #tmpProcedureReports'
	EXEC(@sql)

	set @process = 'CW-8145  Update ReportAgentGI'
	set @sql = 'update GroupByReports set 
columns=''userId|max([user]):user|max([login]):login|sum([tlog]):tlog|sum([tunknown]):tunknown|sum([tav]):tav|sum([tnotav]):tnotav|sum([tother]):tother|sum([tprob]):tprob|sum([tChatting]):tChatting|sum([tManual]):tManual|sum([tundefined]):tundefined|sum([nxferin]):nxferin|sum([nanswerin]):nanswerin|sum([nabndxferin]):nabndxferin|sum([nabndringin]):nabndringin|sum([nabnddlgin]):nabnddlgin|sum([abndaxferin]):abndaxferin|sum([nnoanswerin]):nnoanswerin|sum([nlostin]):nlostin|sum([tdialogin]):tdialogin|sum([tnotesin]):tnotesin|sum([tringin]):tringin|sum([txferin]):txferin|sum([nxferout]):nxferout|sum([nanswerout]):nanswerout|sum([nabndxferout]):nabndxferout|sum([nabndringout]):nabndringout|sum([nabnddlgout]):nabnddlgout|sum([abndaxferout]):abndaxferout|sum([nnoanswerout]):nnoanswerout|sum([nlostout]):nlostout|sum([tdialogout]):tdialogout|sum([tnotesout]):tnotesout|sum([tringout]):tringout|sum([txferout]):txferout|sum([nother]):nother|sum([nmohin]):nmohin|sum([nmohout]):nmohout|sum([nwhagin]):nwhagin|sum([nwhagout]):nwhagout|sum([nwhcliin]):nwhcliin|sum([nwhcliout]):nwhcliout|isnull(sum([tdialogin]+[tdialogout])/nullif(sum([nanswerin]+[nanswerout])_0)_0):tnotavg''
 where id=2010'
	EXEC(@sql)

	
	set @process = 'CW-8145 Alter SP ccspRepAgentGI --Se agrega los casos de cuando la llamada solo pasa a tiempo de notas y se quita el filtro de las llamadas fallidas'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAgentGI] @action AS TINYINT
	,@from AS DATETIME
	,@to AS DATETIME
AS
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

IF @from IS NULL
	SELECT @from = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE()));

IF @to IS NULL
	SELECT @to = GETDATE();

IF @action = 1
BEGIN
	
	DELETE	FROM RepAgentGI	WHERE DATE >= @from	AND DATE < @to

	;with timeDetailAgent as(	
	SELECT userId, timegroup		
		,sum(CASE WHEN tipostatusage_id = 1 THEN tStatus ELSE 0 END) tunknown
		,sum(CASE WHEN tipostatusage_id = 2 THEN tStatus ELSE 0 END) tNotReady
		,sum(CASE WHEN tipostatusage_id IN (3, 31) THEN tStatus ELSE 0 END) tReady 	--3	Ready y 31	Ready PreviewPro	
		,sum(CASE WHEN tipostatusage_id IN (11, 25, 26, 27) THEN tStatus ELSE 0 END) tprob --11 Problem,25 XFER_FAIL, 26 RINGING_FAIL,27 Notas Fallida		
		,sum(CASE WHEN tipostatusage_id = 7 THEN tStatus ELSE 0 END) tother
		,sum(CASE WHEN tipostatusage_id = 7 THEN 1 ELSE 0 END) nother
		,sum(CASE WHEN tipostatusage_id = 21 THEN tStatus ELSE 0 END) tmanualcall		
		,sum(CASE WHEN tipostatusage_id IN (23, 24) THEN tStatus ELSE 0 END) AS tchatting
		,sum(CASE WHEN tipostatusage_id = 30 THEN tStatus ELSE 0 END) AS tReconnectKolob
		,sum(CASE WHEN tipostatusage_id = 32 THEN tStatus ELSE 0 END) AS tPreview
		,sum(CASE WHEN tipostatusage_id = 33 THEN tStatus ELSE 0 END) AS tAssisted
		,sum(CASE WHEN tipostatusage_id = 34 THEN tStatus ELSE 0 END) AS tDialogoWhatsApp
		,sum(CASE WHEN tipostatusage_id = 6 and callId=0 and camType=1 THEN tStatus ELSE 0 END) AS tDispositionOut
		FROM tmpccLogAgentesDia A
		group by A.userId,A.timegroup
	)	
	,inboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,sum(nxfer) AS nxferin
			,sum(nanswer) AS nanswerin
			,sum(nabnd_xfer) AS nabndxferin
			,sum(nabnd_ring) AS nabndringin
			,sum(nabnd_dialog) AS nabnddlgin
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferin
			,sum(nno_answer) AS nnoanswerin
			,sum(nlost) AS nlostin
			,sum(nMoh) AS nMohIn
			,sum(nWHag) AS nWHagIn
			,sum(nWHcl) AS nWHclIn
			,sum(tdialog) AS tdialogIn
			,sum(tnotes) AS tnotesIn
			,sum(tring) AS tringIn
			,sum(txfer) AS txferIn			
		FROM tmpTimesInboundData
		WHERE user_id > 0
		group by timegroup,user_id
		)
		,outboundCount
	AS (
		SELECT timegroup
			,user_id AS userId
			,sum(nxfer) AS nxferOut
			,sum(nanswer) AS nanswerOut
			,sum(nabnd_xfer) AS nabndxferOut
			,sum(nabnd_ring) AS nabndringOut
			,sum(nabnd_dialog) AS nabnddlgOut
			,sum(nabnd_xfer + nabnd_ring + nabnd_dialog) AS abndaxferOut
			,sum(nno_answer) AS nnoanswerOut
			,sum(nlost) AS nlostOut
			,sum(nMoh) AS nMohOut
			,sum(nWHag) AS nWHagOut
			,sum(nWHcl) AS nWHclOut
			,sum(tdialog) AS tdialogOut
			,sum(tnotes) AS tnotesOut
			,sum(tring) AS tringOut
			,sum(txfer) AS txferOut			
		FROM tmpTimesOutboundData
		WHERE user_id > 0
			group by timegroup,user_id
		)
	
	
	
	INSERT INTO RepAgentGI
	SELECT A.timegroup AS [date]
		,A.user_id AS userId
		,u.Nombres + '' '' + u.ApellidoPaterno + '' '' + u.ApellidoMaterno AS [user]
		,u.LOGIN
		,A.tlog
		,isnull(atgStatus.tunknown,0) as tunknown
		,isnull(atgStatus.tReady,0) as tReady
		,isnull(atgStatus.tNotReady,0) as tNotReady
		,isnull(atgStatus.tother,0) as tother
		,isnull(atgStatus.tprob,0) as tprob
		,isnull(atgStatus.tchatting,0) as tchatting
		,isnull(A.tlog-( 
		isnull(atgStatus.tunknown+atgStatus.tReady+atgStatus.tNotReady+atgStatus.tother+atgStatus.tprob+atgStatus.tchatting+atgStatus.tmanualcall,0)
		+ ISNULL(atgStatus.tDispositionOut,0)
		+isnull( txferin+tringin+tdialogin+tnotesIn,0)
		+isnull(txferout+tringout+tdialogout+tnotesout,0)
		
		),0) as tundefined
		
		------------------ Count IN Call -----------------------
		,ISNULL(inCount.nxferin, 0) nXferIn
		,ISNULL(inCount.nanswerin, 0) nAnswerIn
		,ISNULL(inCount.nabndxferin, 0) nAbndXferIn
		,ISNULL(inCount.nabndringin, 0) nAbndRingIn
		,ISNULL(inCOunt.nabnddlgin, 0) AS nAbnddlgIn
		,ISNULL(inCount.abndaxferin, 0) abndaXferIn
		,ISNULL(inCount.nnoanswerin, 0) AS nnoAnswerIn
		,ISNULL(inCount.nlostIn, 0) AS nlostIn
		,isnull(inCount.tdialogIn, 0) AS tdialogIn
		,isnull(inCount.tnotesIn, 0) tnotesIn
		,isnull(inCount.tringIn, 0) tringIn
		,isnull(inCount.txferIn, 0) txferIn

		------------------ Count Out Call -----------------------      
		,isnull(outTime.nXferOut, 0) nXferOut
		,isnull(outTime.nAnswerOut, 0) nAnswerOut
		,isnull(outTime.nAbndXferOut, 0) nAbndXferOut
		,isnull(outTime.nAbndRingOut, 0) nAbndRingOut
		,isnull(outTime.nAbnddlgOut, 0) AS nAbnddlgOut
		,isnull(outTime.abndaXferOut, 0) abndaXferOut
		,isnull(outTime.nnoAnswerOut, 0) AS nnoAnswerOut
		,isnull(outTime.nlostOut, 0) AS nlostOut
		,ISNULL(outTime.tdialogOut, 0) tdialogOut
		,ISNULL(outTime.tnotesOut, 0)+ISNULL(atgStatus.tDispositionOut,0) tnotesOut
		,ISNULL(outTime.tringOut, 0) tringOut
		,ISNULL(outTime.txferOut, 0) txferOut
		
		------------------ Time Agent Common -----------------------      
		,ISNULL(atgStatus.nother,0) nOther
		
		------------------ Count In/Out Call-----------------------      
		,isnull(inCount.nMohIn, 0) AS nMohIn
		,isnull(outTime.nMohOut, 0) AS nMohOut
		,isnull(inCount.nWHagIn, 0) AS nWHagIn
		,isnull(outTime.nWHagOut, 0) AS nWHagOut 
		,isnull(inCount.nWHclIn, 0) AS nWHclIn
		,isnull(outTime.nWHclOut, 0) AS nWHclOut				

		,datepart(yyyy, A.timegroup) AS [year]
		,datepart(mm, A.timegroup) AS [mount]
		,datepart(dd, A.timegroup) AS [day]
		,datepart(HH, A.timegroup) AS [hour]
		,datepart(mi, A.timegroup) AS [minutes]
		,isnull(atgStatus.tmanualcall,0) as tmanualcall
		
	FROM TmpSessionTimeGroup A
	LEFT JOIN ccUserView u ON A.[user_id] = u.[user_id]
	left join timeDetailAgent as atgStatus on atgStatus.userId=A.user_id and atgStatus.timegroup=A.timegroup
	LEFT JOIN inboundCount inCount ON A.timegroup = inCount.timegroup AND A.User_Id = inCount.userId
	left join outboundCount outTime ON outTime.timegroup = A.timegroup AND outTime.userId = A.User_id
		
END;
'
	EXEC(@sql)


	set @process = 'DEV1-339 Alter FN TimeInterval Se modifica para regresar float'
	set @sql = 'ALTER FUNCTION [dbo].[TimeInterval] (@start datetime,@stop datetime,@state1 datetime,@state2 datetime)  
RETURNS float
AS  
BEGIN 
	declare @time float
	
	set @time= 
	case when @start <= @state1 and  @stop > @state1 and @start<= @state2 and  @stop > @state2 then datediff(ms,@state1,@state2)/1000.0
	 when @start<= @state1 and  @stop > @state1 and @stop < @state2 then datediff(ms,@state1,@stop)/1000.0
	 when @start> @state1 and @start<= @state2 and  @stop > @state2 then datediff(ms,@start,@state2)/1000.0
	 when @start> @state1 and @stop < @state2 then datediff(ms,@start,@stop)/1000.0 else  0 end

	RETURN (@time)
END'
	EXEC(@sql)

	set @process = 'CW-8145 Alter SP ccspTimesccLogAgentesDia quita tiempos repetidos y deja el tiempo que debe ser el que tenga mas tiempo de sesion para los indefinidos'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesccLogAgentesDia] @from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL Begin
	DROP TABLE #tempccLogAgentesDia2
End

IF NOT EXISTS (SELECT *	FROM sys.tables	WHERE name = ''tmpccLogAgentesDia'')
BEGIN
	CREATE TABLE tmpccLogAgentesDia (
		id INT NOT NULL 
		,userId INT NOT NULL
		,TipoStatusAge_id TINYINT NOT NULL
		,tStatus FLOAT NOT NULL
		,dateIni DATETIME NOT NULL
		,dateEnd DATETIME NOT NULL
		,currentStatus INT NOT NULL
		,timeGroup DATETIME NOT NULL
		,timeGroupNext DATETIME NOT NULL
		,camId SMALLINT
		,camType SMALLINT
		,callId INT,
		primary key (id,userId)
		);

END
ELSE
BEGIN
	TRUNCATE TABLE tmpccLogAgentesDia	
	
END

IF not EXISTS (SELECT name FROM sys.indexes WHERE name = N''IX_tmpccLogAgentesDia_TipoStatusAge_id'')   Begin
	CREATE NONCLUSTERED INDEX [IX_tmpccLogAgentesDia_TipoStatusAge_id]
	ON [dbo].[tmpccLogAgentesDia] ([TipoStatusAge_id])
	INCLUDE ([tStatus],[timeGroupNext])
end

CREATE TABLE #tempccLogAgentesDia2 (
	rowId INT NOT NULL
	,userId INT NOT NULL
	,TipoStatusAge_id TINYINT NOT NULL
	,tStatus FLOAT NOT NULL
	,dateIni DATETIME NOT NULL
	,dateEnd DATETIME NOT NULL
	,currentStatus INT
	,timeGroup DATETIME NOT NULL
	,timeGroupNext DATETIME NOT NULL
	,camId SMALLINT
	,camType SMALLINT
	,callId INT
	);

WITH tmpLog
AS (
	SELECT User_id AS userId
		,TipoStatusAge_id
		,tStatus
		,DATEADD(ms, - tStatus*1000, fecha) dateIni
		,fecha dateEnd
		,ISNULL(currentStatus, 0) AS currentStatus
		,dbo.GetTimeGroup(DATEADD(ms, - tStatus*1000, fecha), 0) AS timegroup
		,dbo.GetTimeGroup(fecha, 1) AS timegroup_next
		,IdCampEsp AS camId
		,Tipo AS camType
		,callId
	FROM ccLogAgentesDia
	WHERE DATEADD(ss, - tStatus, fecha) BETWEEN @from AND @to 	
	)
, cteLogAgentesDia as (

SELECT ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
	,userId
	,TipoStatusAge_id
	,tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,timegroup
	,timegroup_next
	,camId
	,camType
	,callId
FROM tmpLog
)
insert into tmpccLogAgentesDia
select * from cteLogAgentesDia

/***** Elimina los repetidos ******/
; with regDeleteRepLogout as(
SELECT 
	case when A.dateIni<S.dateIni or A.currentStatus<0 then S.id else A.Id end [rowId]	
	, A.userId		
	FROM tmpccLogAgentesDia A
	LEFT JOIN tmpccLogAgentesDia S ON A.Id = S.Id - 1
		AND A.userId = S.userId
	WHERE A.tStatus >0 and S.tStatus >0
		AND A.TipoStatusAge_id = S.TipoStatusAge_id
		AND A.TipoStatusAge_id>0	
		and (A.dateEnd between S.dateIni and S.dateEnd
		or S.dateEnd between A.dateIni and A.dateEnd
		)
		and ABS( A.tStatus-S.tStatus)<=2
),
rowReconnectLogout as(
select ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId,* 
from tmpccLogAgentesDia where currentStatus in(30,-2) and tStatus>0
)
,
regDeleteReconnect as( 
 select 
case when A.currentStatus=-2 then S.Id else A.Id end [rowId], A.userId
--,A.userId,S.userId,A.RowId,S.RowId,A.timeGroup,S.timeGroupNext,A.id,S.id,A.TipoStatusAge_id,S.TipoStatusAge_id,A.tStatus,S.tStatus
--,A.dateIni,A.dateEnd,S.dateIni,S.dateEnd
--,ABS(A.tStatus-S.tStatus)
from rowReconnectLogout A
inner join rowReconnectLogout S on A.userId=S.userId and A.RowId=S.RowId-1 
and A.TipoStatusAge_id=S.TipoStatusAge_id 
where ( A.dateIni between S.dateIni and S.dateEnd or S.dateIni between A.dateIni and A.dateEnd)
 )
 , rowDelete as(
 select * from regDeleteRepLogout
 union 
 select * from regDeleteReconnect
 )

			
--SELECT A.*
Delete A
from tmpccLogAgentesDia A
inner join rowDelete X  ON A.id = x.rowId AND A.userId = x.userId;

/***** Revisa si es el dia actual para calcular el tiempo del estado ******/
declare @today date,@dateNow datetime
SET @today = convert(DATE, GETDATE(), 121)
SET @dateNow=GETDATE()


IF @today = CONVERT(DATE, @to, 121)
BEGIN
	;	
	WITH tmpAgentLastStatus
	AS (
		SELECT userId ,MAX(dateEnd) AS dateStart
		FROM tmpccLogAgentesDia
		WHERE dateEnd BETWEEN @today AND @to
		GROUP BY userId
		)			

	INSERT INTO tmpccLogAgentesDia
	SELECT 0
		,A.userId
		,A.currentStatus
		,DATEDIFF(ss, A.dateEnd, @dateNow) AS tStatus
		,B.dateStart
		,@dateNow
		,A.currentStatus
		,dbo.GetTimeGroup(B.dateStart, 0) AS timegroup
		,dbo.GetTimeGroup(@dateNow, 1) AS timegroup_next
		,A.camId
		,A.camType
		,A.callId
	FROM tmpccLogAgentesDia A
	INNER JOIN tmpAgentLastStatus B ON A.dateEnd = B.dateStart AND A.userId = B.userId
	WHERE A.dateIni BETWEEN @today AND @to
		AND A.currentStatus NOT IN (- 2, - 1, 0);
END


/***** Separa los estados para tenerlos en intervalos 15 minutos para algunos reportes ******/
INSERT INTO #tempccLogAgentesDia2
SELECT * FROM tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15


DELETE tmpccLogAgentesDia
WHERE DATEDIFF(mi, timegroup, timeGroupNext) > 15;



INSERT INTO tmpccLogAgentesDia
SELECT-1* ROW_NUMBER() OVER (PARTITION BY userId ORDER BY dateIni) AS RowId
	,t.userId
	,TipoStatusAge_id
	,dbo.TimeInterval(th.start, th.stop, dateIni, dateEnd) AS tStatus
	,dateIni
	,dateEnd
	,currentStatus
	,th.start AS timegroup
	,th.stop AS timegroup_next
	,t.camId
	,t.camType
	,t.callId
FROM #tempccLogAgentesDia2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup
		AND t.timeGroupNext
WHERE DATEDIFF(ss, th.start, timeGroupNext) > 0
	AND th.Start BETWEEN @from
		AND @to
order by dateIni,timegroup


IF OBJECT_ID(N''tempdb..#tempccLogAgentesDia2'', N''U'') IS NOT NULL
	DROP TABLE #tempccLogAgentesDia2'
	EXEC(@sql)
	
	set @process = 'CW-8145 Alter Sp ccspTimesOutboundData Se agrega para saber cuando inicio xfer y separar los tiempos correctamente'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesOutboundData] 
@from AS SMALLDATETIME, @to AS SMALLDATETIME
AS
SET NOCOUNT ON

--declare @from AS SMALLDATETIME, @to AS SMALLDATETIME
--set @from=''2023-07-11''
--set @to=dateadd(dd,1,@from)


IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesOutboundData''
		)
BEGIN
	CREATE TABLE tmpTimesOutboundData (
		row INT identity, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, cam_id INT, 
		User_id INT, ntotal INT, nno_agent INT, nxfer INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, nabnd_dialog INT, nanswer INT, 
		nlost INT, tque INT, txfer INT, tring INT, tdialog INT, tnotes INT, tresp INT, nhangup INT, nMoh INT, nWHag INT, nWHcl INT, 
		time_endque DATETIME,dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_out 
		VARCHAR(30), cal_id INT, cal_puerto INT, idwg INT, statuscall_id INT, calif_id INT, cal_manual INT, cal_tMoh INT
		)
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesOutboundData
END

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT max(IDWG) AS IDWG, IdCampEsp AS Id
FROM ccRIACampEspWG
WHERE Tipo = 1
GROUP BY IdCampEsp

DECLARE @HourExtend AS SMALLINT
DECLARE @fromExtended AS SMALLDATETIME
DECLARE @tresRing AS SMALLINT
DECLARE @tresDialog AS SMALLINT
DECLARE @tresDelayIn AS SMALLINT

SELECT @HourExtend = 2

SELECT @fromExtended = DATEADD(hh, - @HourExtend, @from)

EXEC @tresRing = ccspConfigTresRing

EXEC @tresDialog = ccspConfigTresDialog

EXEC @tresDelayIn = ccspConfigtresDelayIn

DECLARE @dateNow DATETIME

SET @dateNow = GETDATE();

WITH outboundData AS (
SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
, cal_inicio AS dateStartDetail	
,cal_id,cam_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas	
,cal_telefono, User_id, statuscall_id, cal_que
,cal_tMoh, cal_whoHung, calif_id, cal_puerto
FROM ccoCallsOut
WHERE cal_inicio between @fromExtended AND @to AND cam_id > 0	
)
,callOutStart as(
select userId,MIN(dateIni) dateIni,callId,camType,camId
from tmpccLogAgentesDia 
where callId>0 and camType=1 and TipoStatusAge_id in(5,9,4,6)
group by userId,callId,camType,camId
)
, callDataStartXfer as(
select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) as dateIni from callOutStart A
inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni 
where B.tStatus>0
group by A.userId,B.callId,B.camType,B.camId
)
,outData  as(
	select 
	
	cal_Inicio AS dateStartDetail	
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS dateEndDetail
	,cam_id,[User_id], 1 AS ntotal
	,CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
	,CASE WHEN statuscall_id >= 10 THEN 1 ELSE 0 END AS nxfer
	,CASE WHEN statuscall_id = 11 THEN 1 ELSE 0 END AS nabnd_xfer
	, CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing THEN 1 ELSE 0 END AS nabnd_ring
	, CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing THEN 1 ELSE 0 END AS nno_answer
	, CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog THEN 1 ELSE 0 END AS nabnd_dialog
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN 1 ELSE 0 END AS nanswer
	, CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
	, cal_twait AS tque, cal_txfer AS txfer, cal_tring AS tring, cal_tdialog AS tdialog, cal_tnotas AS tnotes
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_txfer + cal_tring ELSE 0 END AS tresp
	, CASE WHEN statuscall_id = 6 THEN 1 ELSE 0 END AS nhangup
	, CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
	, CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
	, CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
	, DATEADD(ss, cal_twait, cal_inicio) AS time_endque
	, ISNULL(B.dateIni,A.cal_Inicio) as dateXferAgtStart
	, DATEADD(ss, cal_txfer, ISNULL(B.dateIni,A.cal_Inicio)) AS time_ring
	, DATEADD(ss, cal_txfer + cal_tring, ISNULL(B.dateIni,A.cal_Inicio)) AS time_dialog
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, ISNULL(B.dateIni,A.cal_Inicio)) AS time_notes
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.cal_Inicio)) AS time_end_call
	, cal_telefono AS phone_out, cal_id, cal_puerto, C.idwg AS idwg
	, A.statuscall_id, A.calif_id, A.cal_manual, A.cal_tMoh
	from ccoCallsOut A
	left join callDataStartXfer B on A.cal_id= B.callId and A.cam_id=B.camId
	LEFT JOIN @relastionCampWg C ON A.cam_id = C.camId
	WHERE A.cal_Inicio between @fromExtended AND @to
)

	

INSERT INTO tmpTimesOutboundData (
	dateStartDetail, dateEndDetail, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, nno_answer, nabnd_dialog, 
	nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque,dateXferAgtStart, time_ring, time_dialog, 
	time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id, cal_manual, cal_tMoh, timegroup, 
	timegroup_next
	)
SELECT A.*, dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup, dbo.GetTimeGroup(dateEndDetail, 1) AS timegroup_next
FROM outData A




declare @today date
set @today =convert(date,@dateNow,121)


/******************* Revisa si los datos son del dia ******************************/

IF @today = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId, max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN @today AND @to
		GROUP BY userId
		), timeAcumlate
	AS (
		SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
					ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
			dateEnd, max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN @today	 AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 1
		GROUP BY A.userId, A.camId, A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
				tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
					dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END
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
	dateStartDetail, dateEndDetail, timegroup, timegroup_next, cam_id, User_id, ntotal, nno_agent, nxfer, nabnd_xfer, nabnd_ring, 
	nno_answer, nabnd_dialog, nanswer, nlost, tque, txfer, tring, tdialog, tnotes, tresp, nhangup, nMoh, nWHag, nWHcl, time_endque, 
	dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_out, cal_id, cal_puerto, idwg, statuscall_id, calif_id,  
	cal_manual, cal_tMoh
	)
SELECT dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, cam_id, [User_id]
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_agent ELSE 0 END AS nno_agent
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nxfer ELSE 0 END AS nxfer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_xfer ELSE 0 END AS nabnd_xfer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_ring ELSE 0 END AS nabnd_ring
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nno_answer ELSE 0 END AS nno_answer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nabnd_dialog ELSE 0 END AS nabnd_dialog
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nanswer ELSE 0 END AS nanswer
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nlost ELSE 0 END AS nlost
	, dbo.TimeInterval(th.start, th.stop, dateStartDetail, time_endque) AS tque
	, dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
	, dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
	, dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
	, dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
	, dbo.TimeInterval(th.start, th.stop, dateStartDetail
	, dateadd(ss, tresp, dateStartDetail)) AS tresp
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nhangup ELSE 0 END AS nhangup
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nMoh ELSE 0 END AS nMoh
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHag ELSE 0 END AS nWHag
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  nWHcl ELSE 0 END AS nWHcl
	, time_endque, dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call 
	, phone_out, cal_id, cal_puerto, idwg, statuscall_id
	, CASE WHEN th.start < dateStartDetail AND th.stop < dateEndDetail THEN  calif_id ELSE - 2 END AS calif_id
	, cal_manual
	, dbo.AccountInterval(th.start, th.stop, dateStartDetail, dateEndDetail, cal_tMoh) AS cal_tMoh
	FROM #outboundData2 t
	INNER JOIN TmpTimesInterval th ON  ( t.timegroup > th.Start AND t.timegroup < th.stop)	OR th.Start BETWEEN t.timegroup AND t.timegroup_next
	WHERE datediff(ss, th.start, timegroup_next) > 0
	

IF OBJECT_ID(N''tempdb..#outboundData2'', N''U'') IS NOT NULL
	DROP TABLE #outboundData2'
	EXEC(@sql)

	set @process = 'DEV1-339 Alter Sp ccspTimesInboundData Se agrega para saber cuando inicio xfer y separar los tiempos correctamente'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspTimesInboundData]
@from AS SMALLDATETIME, @to AS SMALLDATETIME
AS

--declare @from AS SMALLDATETIME, @to AS SMALLDATETIME
--set @from=''2023-07-05''
--set @to=dateadd(dd,1,@from)

SET NOCOUNT ON

IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
	DROP TABLE #inboundData2

IF NOT EXISTS (
		SELECT *
		FROM sys.tables
		WHERE name = ''tmpTimesInboundData''
		)
BEGIN
	CREATE TABLE tmpTimesInboundData (
		[row] INT, dateStartDetail DATETIME, dateEndDetail DATETIME, timegroup DATETIME, timegroup_next DATETIME, time_endque 
		DATETIME, dateXferAgtStart datetime, time_ring DATETIME, time_dialog DATETIME, time_notes DATETIME, time_end_call DATETIME, phone_in VARCHAR(40), 
		cal_id INT, dni_id INT, Inbound_id INT, [User_id] INT, ntotal INT, ninitial INT, nout_hour INT, nout_service INT, nabnd INT, 
		nno_agent INT, nque INT, ntimeout INT, noverflow INT, nxfer INT, nxfer_que INT, nabnd_xfer INT, nabnd_ring INT, nno_answer INT, 
		nabnd_dialog INT, nanswer INT, nlost INT, nmsg INT, nabnd_tres INT, nansw_tres INT, tque_max INT, tque INT, txfer INT, tdialog INT, 
		tnotes INT, tring INT, tresp INT, nMoh INT, nWHag INT, nWHcl INT, statusCall_id INT, [dateTResp] DATETIME, [dateTACD] DATETIME, 
		calif_id INT, cal_tMoh INT, cal_puerto INT
		);
END
ELSE
BEGIN
	TRUNCATE TABLE tmpTimesInboundData	
END

DECLARE @relastionCampWg TABLE (idwg INT, camId INT)

INSERT INTO @relastionCampWg
SELECT MAX(IDWG) AS IDWG, IdCampEsp AS Id
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
	SELECT ROW_NUMBER() OVER (ORDER BY cal_id ASC) AS rowId
	, CASE WHEN cal_Xfer IS NULL OR cal_Xfer = ''1900-01-01 00:00:00'' THEN cal_inicio ELSE cal_Xfer END AS dateStartDetail	
	,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas	
	,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
	,cal_tMoh, cal_whoHung, calif_id, cal_puerto
	FROM ccCallsIn
	WHERE cal_inicio between @fromExtended AND @to AND INBOUND_ID > 0	
	)
	,callInStart as(
	select distinct userId,min(dateIni) dateIni,callId,camType
	from tmpccLogAgentesDia 
	where callId>0 and  camType=0 and TipoStatusAge_id in(5,9,4,6)
	group by userId,callId,camType
	) 
	,callDataStartXfer as(
	select A.userId,B.callId,B.camType,B.camId,min(B.dateIni) dateIni from callInStart A
	inner join tmpccLogAgentesDia B on A.userId=B.userId and A.dateIni=B.dateIni
	where B.tStatus>0
	group by A.userId,B.callId,B.camType,B.camId
	),inboundDataWithXferAgent  as(
	select rowId
	,cal_id,Inbound_id,cal_tWait,cal_tXfer,cal_tRing,cal_tDialog,cal_tNotas	
	,dateStartDetail	
	,DATEADD(ss, cal_tWait, A.dateStartDetail) as time_endque
	,ISNULL(B.dateIni,A.dateStartDetail) as dateXferAgtStart
	,DATEADD(ss, cal_txfer + cal_tring + cal_tdialog + cal_tnotas, ISNULL(B.dateIni,A.dateStartDetail)) as dateEndDetail
	,cal_Ani, dni_id, User_id, statuscall_id, cal_que, cal_Xfer
	,cal_tMoh, cal_whoHung, calif_id, cal_puerto
	from inboundData A
	left join callDataStartXfer B on A.cal_id= B.callId and A.Inbound_id=B.camId and A.User_id=B.userId
	)	
	

	

	INSERT INTO tmpTimesInboundData
	select rowId, dateStartDetail,dateEndDetail
	, dbo.GetTimeGroup(dateStartDetail, 0) AS timegroup
	, dbo.GetTimeGroup(dateEndDetail, 1	) AS timegroup_next
	, time_endque, dateXferAgtStart
	, DATEADD(ss, cal_txfer, dateXferAgtStart) AS time_ring
	, DATEADD(ss, cal_txfer + cal_tring, dateXferAgtStart) AS time_dialog
	, DATEADD(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS time_notes	
	, dateEndDetail AS time_end_call
	, cal_Ani AS phone_in, cal_id, dni_id, Inbound_id, [User_id], 1 AS ntotal
	, CASE WHEN statuscall_id = 1 THEN 1 ELSE 0 END AS ninitial
	, CASE WHEN statuscall_id = 2 THEN 1 ELSE 0 END AS nout_hour
	, CASE WHEN statuscall_id = 3 THEN 1 ELSE 0 END AS nout_service
	, CASE WHEN statuscall_id IN (5, 6)	AND cal_que > 0	AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd
	, CASE WHEN statuscall_id = 4 THEN 1 ELSE 0 END AS nno_agent
	, CASE WHEN cal_que > 0 THEN 1 ELSE 0 END AS  nque
	, CASE WHEN statuscall_id = 7 THEN 1 ELSE 0 END AS ntimeout
	, CASE WHEN statuscall_id = 8 THEN 1 ELSE 0 END AS noverflow
	, CASE WHEN statuscall_id IN (11, 15, 13, 16)OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'' ) THEN 1 ELSE 0 END AS nxfer
	, CASE WHEN cal_que > 0	AND ( statuscall_id IN (11, 15, 13, 16) OR ( statuscall_id = 6	AND cal_xfer <> ''1900-01-01 00:00:00'') ) THEN 1 ELSE 0 END AS nxfer_que
	, CASE WHEN statuscall_id = 11 OR (statuscall_id = 6 AND cal_xfer <> ''1900-01-01 00:00:00'') THEN 1 ELSE 0 END AS nabnd_xfer
	, CASE WHEN statuscall_id = 15 AND cal_tring <= @tresRing	 THEN 1 ELSE 0 END AS nabnd_ring
	, CASE WHEN statuscall_id = 15 AND cal_tring > @tresRing  THEN 1 ELSE 0 END AS nno_answer
	, CASE WHEN statuscall_id = 13 AND cal_tdialog <= @tresDialog  THEN 1 ELSE 0 END AS nabnd_dialog
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog   THEN 1 ELSE 0 END AS nanswer
	, CASE WHEN statuscall_id = 16 THEN 1 ELSE 0 END AS nlost
	, CASE WHEN statuscall_id IN (9, 10, 12, 14)  THEN 1 ELSE 0 END AS nmsg
	, CASE WHEN ( (	statuscall_id IN (5, 6) AND cal_que > 0	AND (cal_xfer IS NULL OR cal_xfer = ''1900-01-01 00:00:00'')	)
					AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn)) THEN 1 ELSE 0 END AS nabnd_tres
	, CASE WHEN ((statuscall_id = 13 AND cal_tdialog > @tresDialog)	AND (cal_twait + cal_txfer + cal_tring < @tresDelayIn) ) THEN 1 ELSE 0 END AS nansw_tres	
	, cal_twait AS tque_max, cal_twait AS tque, cal_txfer AS txfer, cal_tdialog AS tdialog
	, cal_tnotas AS tnotes, cal_tring AS tring
	, CASE WHEN statuscall_id = 13 AND cal_tdialog > @tresDialog THEN cal_twait + cal_txfer + cal_tring ELSE 0 END AS tresp
	, CASE WHEN cal_tMoh > 0 THEN 1 ELSE 0 END AS nMoh
	, CASE WHEN cal_whoHung > 0 THEN 1 ELSE 0 END AS nWHag
	, CASE WHEN cal_whoHung = 0 THEN 1 ELSE 0 END AS nWHcl
	, statusCall_id
	, dateadd(ss, cal_txfer + cal_tring, dateXferAgtStart) AS [dateTResp]
	, dateadd(ss, cal_txfer + cal_tring + cal_tdialog, dateXferAgtStart) AS [dateTACD]
	, calif_id, cal_tMoh, cal_puerto
	from inboundDataWithXferAgent

/******************* Revisa si los datos son del dia ******************************/

declare @today date
set @today =convert(date,@dateNow,121)

IF @today = CONVERT(DATE, @to, 121)
BEGIN
		;

	WITH lastAgentStatus
	AS (
		SELECT userId, max(dateIni) dateIn
		FROM tmpccLogAgentesDia
		WHERE dateIni BETWEEN @today AND @to
		GROUP BY userId
		), timeAcumlate
	AS (
		SELECT A.userId, A.camId, A.callId, sum(CASE WHEN A.currentStatus IN (4, 5, 9) THEN A.tStatus 
					ELSE 0 END) AS tdialog, sum(CASE WHEN A.currentStatus = 6 THEN A.tStatus ELSE 0 END) AS tnotes, max(A.dateEnd) AS 
			dateEnd, max(A.timeGroupNext) AS timeGroupNext
		FROM tmpccLogAgentesDia A
		INNER JOIN lastAgentStatus B ON A.userId = B.userId
			AND A.dateIni = B.dateIn
		WHERE A.dateIni BETWEEN @today AND @to
			AND currentStatus IN (4, 5, 6, 9)
			AND A.camType = 0
		GROUP BY A.userId, A.camId, A.callId
		)
	UPDATE A
	SET A.dateEndDetail = B.dateEnd, A.timegroup_next = B.timeGroupNext, A.tdialog = CASE WHEN B.tdialog > 0 THEN B.tdialog ELSE A.
				tdialog END, A.tnotes = CASE WHEN B.tnotes > 0 THEN B.tnotes ELSE A.tnotes END, A.time_notes = CASE WHEN B.tdialog > 0 THEN B.
					dateEnd ELSE A.time_dialog END, A.time_end_call = CASE WHEN B.tnotes > 0 THEN B.dateEnd ELSE A.time_notes END, A.
		User_id = CASE WHEN A.User_id > 0 THEN B.userId ELSE A.User_id END
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
SELECT [row], dateStartDetail, dateEndDetail, th.start AS timegroup, th.stop AS timegroup_next, time_endque
,dateXferAgtStart, time_ring, time_dialog, time_notes, time_end_call, phone_in, cal_id, dni_id, Inbound_id, [User_id] 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntotal ELSE 0 END AS ntotal 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ninitial ELSE 0 END AS ninitial 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_hour ELSE 0 END AS nout_hour 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nout_service ELSE 0 END AS nout_service 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd ELSE 0 END AS nabnd 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_agent ELSE 0 END AS nno_agent 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nque ELSE 0 END AS nque 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN ntimeout ELSE 0 END AS ntimeout 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN noverflow ELSE 0 END AS noverflow 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer ELSE 0 END AS nxfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nxfer_que ELSE 0 END AS nxfer_que 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_xfer ELSE 0 END AS nabnd_xfer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_ring ELSE 0 END AS nabnd_ring 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nno_answer ELSE 0 END AS nno_answer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_dialog ELSE 0 END AS nabnd_dialog 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nanswer ELSE 0 END AS nanswer 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nlost ELSE 0 END AS nlost 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nmsg ELSE 0 END AS nmsg 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nabnd_tres ELSE 0 END AS nabnd_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nansw_tres ELSE 0 END AS nansw_tres 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN tque_max ELSE 0 END AS tque_max
, dbo.TimeInterval(th.start, th.stop, dateStartDetail, 	time_endque) AS tque
, dbo.TimeInterval(th.start, th.stop, dateXferAgtStart, time_ring) AS txfer
, dbo.TimeInterval(th.start, th.stop, time_dialog, time_notes) AS tdialog
, dbo.TimeInterval(th.start, th.stop, time_notes, time_end_call) AS tnotes
, dbo.TimeInterval(th.start, th.stop, time_ring, time_dialog) AS tring
, dbo.TimeInterval(th.start, th.stop, dateStartDetail, DATEADD(ss, tresp, dateStartDetail)) AS tresp 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nMoh ELSE 0 END AS nMoh 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHag ELSE 0 END AS nWHag 
, CASE WHEN th.start <  dateStartDetail AND th.stop < dateEndDetail THEN nWHcl ELSE 0 END AS nWHcl, statusCall_id, [dateTResp], [dateTACD] 
, CASE WHEN th.start >  dateStartDetail AND th.stop > dateEndDetail THEN calif_id ELSE - 2 END AS calif_id, dbo.AccountInterval(th.start, th.stop, dateStartDetail
		, dateEndDetail, cal_tMoh) AS cal_tMoh, cal_puerto
FROM #inboundData2 t
INNER JOIN TmpTimesInterval th ON (
		t.timegroup > th.Start
		AND t.timegroup < th.stop
		)
	OR th.Start BETWEEN t.timegroup AND t.timegroup_next
WHERE DATEDIFF(ss, th.start, timegroup_next) > 0
	AND th.Start BETWEEN @from AND @to
ORDER BY [row], th.start


IF OBJECT_ID(N''tempdb..#inboundData2'', N''U'') IS NOT NULL
	DROP TABLE #inboundData2
'
	EXEC(@sql)


	set @process = 'CW-8145 Alter SP ccspGenSession se quita tiempos repetidos'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspGenSession]
@from AS SMALLDATETIME,
@to AS SMALLDATETIME
AS
SET NOCOUNT ON

DECLARE @date DATETIME,@today datetime

IF OBJECT_ID(''tempdb..#tempccGenSession'') IS NOT NULL DROP TABLE #tempccGenSession


CREATE TABLE #tempccGenSession ([fila] INT NOT NULL, [user_id] [smallint] NOT NULL, [login] [datetime] NULL, [logout] [datetime] NULL, [extension] [varchar](7) NOT NULL, PRIMARY KEY (fila, user_id))


declare @dataLoginLogout table(Fila int not null,User_id int not null,Extension [varchar](7),TipoMov int not null,fecha datetime not null)

;with dataLoginLogout as(
select ROW_NUMBER() OVER (
PARTITION BY user_id ORDER BY FECHA, tipoMov
) Fila
,User_id,Extension,TipoMov,
fecha 
from ccLogLogin where fecha between @from and @to 
--
)
, filterLoginLogout as(
select A.Fila,  A.User_id
,A.fecha LOGIN,  S.fecha logout
, A.Extension
from dataLoginLogout A
left join dataLoginLogout S on A.Fila =S.Fila-1 AND A.User_id = S.User_id
and A.TipoMov=1 and S.TipoMov=0
where A.TipoMov=1
union
select A.Fila,A.User_id
,case when  A.TipoMov=1 then A.fecha end LOGIN
,case when  S.TipoMov=0 then S.fecha  end logout
, A.Extension
from dataLoginLogout A
inner join dataLoginLogout S on A.Fila =S.Fila-1 AND A.User_id = S.User_id
and A.TipoMov=S.TipoMov
)

INSERT INTO #tempccGenSession
select ROW_NUMBER() OVER (
PARTITION BY user_id ORDER BY Fila
) Fila,User_id,LOGIN,logout,Extension from 
filterLoginLogout A
--where User_id=@userId

;with dataLoginNull as(
select A.Fila,A.user_id,S.Logout, A.Logout Logout2
from #tempccGenSession A 
left join #tempccGenSession S on A.fila=S.fila+1 and A.user_id=S.user_id 
where A.login is null
), dataLoginRecovery as(
select A.Fila,A.user_id,
(
select min( fecha) from ccLogAgentesDia B
where B.fecha between A.Logout and A.Logout2
	and B.User_id=A.user_id
	and currentStatus>=0
) as Login
from dataLoginNull A
)

update B set B.Login=A.Login
from dataLoginRecovery A
inner join #tempccGenSession B on A.fila=B.fila and A.user_id=B.user_id
where A.Login is not null



;with dataLogoutNull as(
select A.Fila,A.user_id,A.login,S.login login2
from #tempccGenSession A 
left join #tempccGenSession S on A.fila=S.fila-1 and A.user_id=S.user_id 
where A.logout is null
)
, dataLogoutRecovery as(
select A.Fila,A.user_id,
A.login, A.login2,
(
select max( fecha) from ccLogAgentesDia B
where B.fecha between A.login and A.login2
	and B.User_id=A.user_id
	and currentStatus<=0
) as logout
from dataLogoutNull A
)

update B set B.logout=A.logout
from dataLogoutRecovery A
inner join #tempccGenSession B on A.fila=B.fila and A.user_id=B.user_id
where A.logout is not null


set @today=CONVERT(date,getdate(),121)
set @date=GETDATE()

--Revisa el ultimo Login que tenga Logout para poner GETDATE()
if @today=CONVERT(date,@to,121) begin
	
	;with LastLoginToday as(
	SELECT MAX(login) login, user_id
		FROM #tempccGenSession
		WHERE login>@today --and logout IS NULL 
		GROUP BY user_id
	)
	update B
	set B.logout=@date
	from LastLoginToday A
	inner join #tempccGenSession B on A.login=B.login and A.user_id=B.user_id
	where B.logout is null	
end

;with registryDelete as(
select A.fila,A.user_id
from #tempccGenSession A 
left join #tempccGenSession S on A.fila=S.fila-1 and A.user_id=S.user_id 
and A.logout is null
where DATEDIFF(ss,A.login,S.login) =0
)

----Borra los registros que tienen menos de un 1 segundo y que el logout es null
Delete B
from registryDelete A
inner join #tempccGenSession B on A.fila=B.fila and A.user_id=B.user_id

delete from #tempccGenSession where login is null
delete from #tempccGenSession where logout is null

;with updateRow as(
select ROW_NUMBER() OVER (
PARTITION BY user_id ORDER BY Fila
) Filanew, fila,user_id, login,logout, extension
from #tempccGenSession A
) 

update B set
B.fila=A.Filanew
from updateRow A
inner join #tempccGenSession B on A.fila=B.fila and A.user_id=B.user_id

;WITH tmpccGenSession
AS (
	SELECT user_id, [login], [logout], extension
	, dbo.GetTimeGroup([login], 0) AS timeGroup, dbo.GetTimeGroup([logout], 1) AS timeGroupNext
	FROM #tempccGenSession
	)
SELECT A.*, datediff(ss, [login], [logout]) AS tlog
FROM tmpccGenSession A

IF OBJECT_ID(''tempdb..#tempccGenSession'') IS NOT NULL DROP TABLE #tempccGenSession


SET NOCOUNT OFF'
	EXEC(@sql)

	set @process = 'DEV1-393 Alter SP  ccspRepOutDialDetail Grescoce se valida if exists(select *  from DC_Extra) evitar procesar si no esta llena'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 

@action AS TINYINT, 
@from AS   DATETIME = NULL, 
@to AS     DATETIME = NULL
AS
SET NOCOUNT ON

IF @from IS NULL
	SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
if @to is null
	SELECT @to = GETDATE()

IF @action = 1
BEGIN  

DECLARE @country SMALLINT
SELECT @country = valor
FROM ccSettings
WHERE setting_id = 104

--Borrar lo que esta para no repetir          
DELETE FROM RepOutDialDetail WHERE date >= @from AND date < @to
        
	IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
	IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
	IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;

	create table #dials (
	logDial_id	int not null,
	callout_id	int not null,
	cam_id	smallint not null,
	tipoResDial_id	int not null,
	resultDialDesc	varchar(60) not null,
	Telefono	varchar(32) not null,
	Puerto	smallint not null,
	fecha	datetime not null,
	tDialing	smallint not null,
	dialType	varchar(50) not null,
	tBusy	smallint  not null,
	answerbit	bit not null,
	canceledNoAgents	bit not null,
	cal_id	int not null,
	disconnectCause	varchar(250) not null,
	cal_key	varchar(40) not null,
	file_moved	varchar(100)  null,
	tipoLlamada_id	smallint null,
	CallDisposition	varchar(150) null,
	califSubDesc	varchar(150) null,
	codeSip	varchar(10) not null,
	TipoTel	varchar(30)  not null,
	tpreview	smallint not null,
	UserID	smallint null,
	)

	CREATE NONCLUSTERED INDEX IX_dials_Tmp1 ON #dials ([codeSip])INCLUDE ([disconnectCause])

	
	create table #relationCodeSip(
	codeSip int not null,
	disconnectCause varchar(250),
	description varchar(250)
	)

	insert into #dials
	SELECT	dial.logDial_id
		,dial.callout_id
		,dial.cam_id
		,CASE WHEN dial.canceledNoAgents = 1 THEN 14 ELSE dial.tipoResDial_id END AS tipoResDial_id
		,ISNULL(tr.descripcion ,'''') as resultDialDesc
		,dial.Telefono
		,dial.Puerto
		,dial.fecha
		,dial.tDialing
		,CASE WHEN dial.TipoDialingMode = ''100000000'' THEN ''systemTranslated_Preview'' 
			  WHEN LEFT(dial.TipoDialingMode, 1) = ''1'' THEN ''systemTranslated_Assisted'' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) = ''00'' THEN ''systemTranslated_Auto'' 
			  WHEN RIGHT(dial.TipoDialingMode, 2) IN (''10'', ''01'') THEN ''systemTranslated_Manual'' END AS dialType			  
		,dial.tBusy
		,dial.answerbit
		,dial.canceledNoAgents
		,dial.cal_id
		,dial.disconnectCause
		,isnull(co.cal_key,dial.cal_key) cal_key 
		,case when co.file_moved=2 then ''systemTranslated_Remoto'' else ''Local'' end file_moved-- isnull(co.file_moved,0) as file_moved
		,dial.tipoLlamada_id
		,tco.[Description] AS CallDisposition
		,tsco.califSubDesc
		,CASE WHEN dial.disconnectCause <> '''' THEN SUBSTRING(dial.disconnectCause, 21, 3) ELSE '''' END codeSip
		,case when @country<>1 then '''' WHEN dial.tipoLlamada_id IN (1, 2, 5) THEN ''systemTranslated_fijo'' 
			WHEN dial.tipoLlamada_id IN (3, 4) THEN ''systemTranslated_cellPhone'' ELSE ''systemTranslated_Indefinite'' END TipoTel
		,ISNULL(regp.tPreview,'''') as tpreview
		,co.User_id as UserID	
	FROM ccoLogDials dial(NOLOCK)
	LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
	LEFT JOIN cctipocalifout tco WITH (NOLOCK) ON tco.calif_id = co.calif_id
	LEFT JOIN cctipocalifsubout tsco WITH (NOLOCK) ON tsco.califSub_id = co.califSub_id
	LEFT JOIN RegProcessPreviewRecord regp WITH (NOLOCK) ON regp.callout_id = co.callout_id and regp.callId = co.cal_id
	LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dial.tipoResDial_id = tr.tiporesdial_id
	WHERE fecha >= @from AND fecha < @to

	insert into #dials
	select 
			0 as logDial_id 
			,reg.callout_id
			,ccoa.cam_id
			,reg.process
			,ISNULL(cctyp.translatedDesc,'''')
			,ccoa.cal_telefono
			,0 as Puerto
			,reg.reg_date
			,0 as tDialing
			,''systemTranslated_Preview'' as dialType	  
			,0 as tBusy
			,0 as answerbit
			,0 as canceledNoAgents
			,0 as cal_id
			,'''' as disconnectCause
			,ccoa.cal_Key
			,''Local'' as file_moved 
			,0 as tipoLlamada_id
			,'''' as CallDisposition
			,'''' as califSubDesc
			,'''' as codeSip
			,''systemTranslated_Indefinite'' as TipoTel
			,reg.tPreview
			,reg.userId 
	FROM RegProcessPreviewRecord reg(NOLOCK)
	left join ccoCallsOutSource ccoa (NOLOCK) ON reg.callout_id = ccoa.callout_id
	left join ccTypeProcessPreview cctyp (NOLOCK) ON  cctyp.typeProcess_id = reg.process
	WHERE reg.reg_date >= @from AND reg.reg_date < @to AND reg.process !=7
	

	
	if exists(select *  from DC_Extra) begin
		;with codeSips as (
			select distinct codeSip as codeSip,disconnectCause 			
			from #dials where codeSip<>''''
		)	

		select cast(codeSip as int) as codeSip,disconnectCause 
		into #codeSip 
		from codeSips where IsNumeric(codeSip)=1
	
		insert into #relationCodeSip
		select A.codeSip,A.disconnectCause,B.description 		
		from #codeSip A
		inner join DC_Extra B on A.codeSip=B.id

	end

--Inserta informacon de reporte  
	INSERT INTO RepOutDialDetail
		SELECT fecha as [date]
		,case when dials.cal_key is null or  cs.cal_key is null then '''' when dials.cal_key is not null then dials.cal_key else cs.cal_key end cal_key
		,telefono telephone
		,dials.tiporesdial_id as tiporesdialId
		,CASE WHEN dials.tipoResDial_id = 14 THEN ''systemTranslated_CancelledBySystem'' ELSE ISNULL(dials.resultDialDesc, '''') END AS dialResult
		,dials.[cam_id] campaignId
		,ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campaign
		,dials.tbusy AS timeMessage
		,DATEPART(yyyy, fecha) year	
		,DATEPART(mm, fecha) month	
		,DATEPART(dd, fecha) day	
		,DATEPART(hh, fecha) hour	
		,DATEPART(mi, fecha) minutes
		,ISNULL(rl.name, '''') listName
		,CASE WHEN answerbit = 1 THEN ''systemTranslated_Charged'' ELSE ''systemTranslated_NotCharged'' END AS billed
		,ISNULL(cs.Dato1, '''') AS data1
		,ISNULL(cs.Dato2, '''') AS data2
		,ISNULL(cs.Dato3, '''') AS data3
		,ISNULL(cs.Dato4, '''') AS data4
		,ISNULL(cs.Dato5, '''') AS data5
		--,CASE WHEN dials.[file_moved] = 1 THEN ''systemTranslated_Remoto'' ELSE ''Local'' END AS fileMoved
		,dials.[file_moved] AS fileMoved
		,dials.disconnectCause
		,COALESCE(dat.description, descripcion, ''N/A'') DCCustomer
		,dials.dialType
		,TipoTel
		,ISNULL(CallDisposition, ''N/A'') AS CallDisposition
		,ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
		,ISNULL(csP.Dato6, '''') AS data6
		,ISNULL(csP.Dato7, '''') AS data7
		,ISNULL(csP.Dato8, '''') AS data8
		,ISNULL(csP.Dato9, '''') AS data9
		,ISNULL(csP.Dato10, '''') AS data10
		,ISNULL(csP.Dato11, '''') AS data11
		,ISNULL(csP.Dato12, '''') AS data12
		,ISNULL(csP.Dato13, '''') AS data13
		,ISNULL(csP.Dato14, '''') AS data14
		,ISNULL(csP.Dato15, '''') AS data15
		,dials.tpreview AS preview_Time
		,ISNULL(us.Login,'''') as [login]
	FROM #dials as dials
	LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
	LEFT JOIN cctipoResultadoDial tr(NOLOCK) ON dials.tiporesdial_id = tr.tiporesdial_id
	LEFT JOIN ccCamps camps(NOLOCK) ON camps.[cam_id] = dials.[cam_id]
	LEFT JOIN ccRIARegistryLists rl(NOLOCK) ON cs.list_id = rl.list_id
	LEFT JOIN #relationCodeSip dat ON dat.disconnectCause = dials.disconnectCause
	LEFT JOIN ccoCallsPreviewData csP ON (dials.cal_Key = csP.cal_Key AND dials.cam_id = csP.cam_id)
	LEFT JOIN ccUsers us (NOLOCK) ON  us.User_id = dials.UserID

	IF OBJECT_ID(''tempdb..#dials'') IS NOT NULL drop table #dials
	IF OBJECT_ID(''tempdb..#codeSip'') IS NOT NULL drop table #codeSip;
	IF OBJECT_ID(''tempdb..#relationCodeSip'') IS NOT NULL drop table #relationCodeSip;
END'
	EXEC(@sql)

	set @process = 'CW-8145 '
	set @sql = ''
	EXEC(@sql)


	
-------------------------------------------------------------------------------------------------------------------


--	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
