/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 133 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	-------------------------------------------------- Frida Orta Begin -----------------------------------------------------------------------------------
	set @process = 'DROP VIEW RepViewOutCallsDetail'
	set @sql = '
	if exists (select * FROM sys.views where name = N''RepViewOutCallsDetail'')
    begin
       DROP VIEW RepViewOutCallsDetail
    end'
	EXEC(@sql)

	set @process = 'CREATE VIEW RepViewOutCallsDetail se quita columna campaignId'
	set @sql = '
	CREATE VIEW [dbo].[RepViewOutCallsDetail] AS 
	SELECT
	date,
	callKey,
	telephone,
	transfer,
	dialog,
	nque,
	wrapup,
	CallDisposition,
	subDisposition,
	extension,
	userId,
	[login] [userName],
	username [login],
	campaignId,
	campaign,
	duration,
	ncost,
	iva,
	total as totalRow,
	ByCarrier,
	Calltypes,
	dialType,
	whoHangUp,
	dialResult as callStatus,
	calId,
	year,
	month,
	day,
	hour,
	minutes,
	trunk,
	data1 [Dato1],
	data2 [Dato2],
	data3 [Dato3],
	data4 [Dato4],
	data5 [Dato5],
	MessageTime,
	grabId  
	FROM RepOutCallsDetail nolock'
	EXEC(@sql)

	set @process = 'DROP VIEW RepViewSpecialAbndCamp'
	set @sql = '
	if exists (select * FROM sys.views where name = N''RepViewSpecialAbndCamp'')
    begin
       DROP VIEW RepViewSpecialAbndCamp
    end'
	EXEC(@sql)

	set @process = 'CREATE VIEW RepViewSpecialAbndCamp se quita columna campaignId'
	set @sql = '
	CREATE VIEW RepViewSpecialAbndCamp AS SELECT
	date,
	campaignId,
	campaign,
	dialedCalls,
	abandonedCalls,
	abandonedCallsPctg,
	year,
	month,
	day,
	hour,
	minutes
	FROM RepSpecialAbndCamp nolock'
	EXEC(@sql)
	-------------------------------------------------- Frida Orta End -----------------------------------------------------------------------------------
	----------------------------------------------- Gaby Begin ----------------------------------------------------------------------------------
		SET @process = 'DROP VIEW RepViewOutAnswAndXferCalls'
	SET @sql = 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(''RepViewOutAnswAndXferCalls'') AND type = ''V'')
	    BEGIN
	        DROP VIEW RepViewOutAnswAndXferCalls
	    END'
	EXEC(@sql)


	SET @process = 'CREATE VIEW RepViewOutAnswAndXferCalls'
	SET @sql = '
	CREATE VIEW RepViewOutAnswAndXferCalls
	as
	select
		[date],
		[callid],
		[campaignId],
		[campaign],
		[userId],
		[Agent],
		[dialog],
		[telephone],
		[dialId],
		[dialType],
		[CallTypes],
		[ncost],
		case when CHARINDEX(''%'',cast([iva] as varchar(3))) > 0 THEN [iva] else cast([iva] as varchar(3))+''%'' end [iva],
		[total],
		[trunk],
		[ANI] ,
		[dialTimeSec]
	from RepOutAnswAndXferCalls NOLOCK'
	EXEC(@sql)
	-------------------------------------------------- Gaby End -----------------------------------------------------------------------------------
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
