/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2017/19/01
Description:
**********************************************************************************************
	Se crea reporte
Database: ccReportsRia
Required version: 41



IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/


set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version =42
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1 begin
	begin tran
	begin try

	set @process = 'AnsweredCallsbyDialingRetries - Tabla'
	set @Sql= '
	IF NOT EXIST (SELECT * FROM sys.tables where name = N''RepAnsweredCallsByDialingRetries'')
	BEGIN
		create table [dbo].[RepAnsweredCallsByDialingRetries](
			[date] [datetime] NOT NULL,
			[calId] [int] NOT NULL,
			[telephone] [varchar](30) NOT NULL,
			[dialResultId] [int] NOT NULL,
			[dialResult] [varchar](20) NOT NULL,
			[tries] [int] NOT NULL,
			[campaignId] [smallint] NOT NULL,
			[campaing] [varchar](40) NOT NULL,
			[userId] [smallint] NOT NULL,
			[agentName] [varchar](115) NOT NULL,
			[extension] [varchar](7) NOT NULL,
			[startHour] [varchar](12) NOT NULL,
			[endHour] [varchar](12) NOT NULL,
			[dialogTime] [smallint] NOT NULL,
			[dispositionId] [smallint] NOT NULL,
			[subDispositionId] [smallint] NOT NULL,
			[disposition] [varchar](40) NOT NULL,
			[subDisposition] [varchar](40) NOT NULL,
			[wrapup] [smallint] NOT NULL,
			[year] [int] NOT NULL,
			[month] [int] NOT NULL,
			[day] [int] NOT NULL,
			[hour] [int] NOT NULL,
			[minutes] [int] NOT NULL
		) ON [PRIMARY]
	END
	'
	EXEC(@sql)
	set @process = 'AnsweredCallsbyDialingRetries - Procedimiento Almacenado'
	set @Sql= '
	IF NOT EXIST (SELECT * FROM sys.procedures where name = N''RepAnsweredCallsByDialingRetries'')
	BEGIN
		CREATE PROCEDURE [ccspRepAnsweredCallsByDialingRetries]
		@action as tinyint,
		@from AS datetime = null,
		@to AS datetime = null
		AS
		if @from is null
			select @from = convert(datetime,convert(varchar(11),getdate()))
		if @to is null	
			select @to = getdate()

		if @action = 1
		begin

			--Borrar lo que esta para no repetir
			delete from RepAnsweredCallsByDialingRetries with(rowlock)
			where date >= @from and date < @to

			INSERT INTO RepAnsweredCallsByDialingRetries
			select 
			A.cal_Inicio as [date],
			A.cal_id as [calId],
			A.cal_telefono as [telephone],
			B.tipoResDial_id as [dialResultId],
			resDial.descripcion as [dialResult],
			C.cal_intentos as [tries], -- añadir a aspx
			A.cam_id as [campaignId],
			E.cam_descripcion as [campaign],
			A.User_id as [userId],
			D.Nombres+' '+ D.ApellidoPaterno+' '+D.ApellidoMaterno as [agentName],
			(select top 1 Extension from ccLogLogin where user_id=A.User_id and tipoMov=1 and fecha<A.cal_inicio order by fecha desc) as [extension],
			convert(varchar(12),A.cal_Inicio,108) as [startHour], -- añadir a aspx
			convert(varchar(12),dateadd(ss,A.cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,A.cal_Inicio),108) as [endHour], -- añadir a aspx
			cal_tDialog as [dialogTime],
			isnull(A.calif_id,0) as [dispositionId],
			isnull(A.califSub_id,0) as [subDispositionId],
			isnull(disp.Description,''systemTranslated_Dispositionless'') as [disposition],
			isnull(subDisp.califSubDesc,''systemTranslated_NoSubDisposition'') as [subDisposition],
			A.cal_tNotas as [wrapup],
			datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) AS [year],
			datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [month],
			datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [day],
			datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [hour],
			datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),fecha,121)+ '':00'',121)) as [minutes]
			
			from ccoCallsOut A 
			left join ccoLogDials B on A.cal_id=B.cal_id
			left join ccoCallsOutSource C on C.callout_id=A.callout_id
			left join ccUsers D on A.User_id=D.User_id
			left join ccCamps E on A.cam_id=E.cam_id
			left join ccTipoCalifOUT disp On disp.calif_id=A.calif_id
			left join ccTipoCalifSubOUT subDisp On subDisp.califSub_id=A.califSub_id
			left join ccTipoResultadoDial resDial on resDial.tipoResDial_id=B.tipoResDial_id

			where A.cal_Inicio >= @from 
			and A.cal_Inicio < @to
			and A.cal_manual in(0,2)
			order by date
		END
	END
	'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - filtros fecha y seleccion'
	set @Sql= '
	IF !EXIST (SELECT * FROM [ReportsFiltersMenus]
	WHERE [ReportsFiltersMenus].[idReport] = 4190)
	BEGIN
		INSERT INTO [ReportsFiltersMenus] (idReport, filterMenuName) VALUES (4190, N''date'')
		INSERT INTO [ReportsFiltersMenus] (idReport, filterMenuName) VALUES (4190, N''filterby'')
	END
	'
	EXEC(@sql)


	set @process = 'AnsweredCallsbyDialingRetries - filtros usuario campaña y resultado de marcación'
	set @Sql= '
	IF !EXIST (SELECT * FROM [ReportsFilters]
	WHERE [ReportsFilters].[id] = 4190)
	BEGIN
		INSERT INTO ReportsFilters VALUES(''Answered Calls by Dialing Retries'', ''campaigns'', 4190)
		INSERT INTO ReportsFilters VALUES(''Answered Calls by Dialing Retries'', ''users'', 4190)
		INSERT INTO ReportsFilters VALUES(''Answered Calls by Dialing Retries'', ''dialresults'', 4190)
	END
	'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - Totales'
	set @Sql= '
	IF !EXIST (SELECT * FROM [ReportsTotals]
	WHERE [ReportsTotals].[id] = 4190)
	BEGIN
		INSERT INTO ReportsTotals values (4190, '''')
	end
	'
	EXEC(@sql)

	set @process = 'AnsweredCallsbyDialingRetries - Traducciones'
	set @Sql= '
	IF !EXIST (SELECT * FROM [TranslatedReports]
	WHERE [TranslatedReports].[id] = 4190)
	BEGIN
		INSERT INTO TranslatedReports VALUES(4190, ''disposition|subDisposition'')
	END
	'
	EXEC(@sql)

	set @process = ''
	set @Sql= '

	'
	EXEC(@sql)

	commit tran
	end try

	begin catch

	/* Error generated based on sintax */
	select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
	RAISERROR(@errorGenerated, 11, 1)

	rollback tran
	end catch
end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off