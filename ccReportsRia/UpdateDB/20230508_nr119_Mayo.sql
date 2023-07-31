SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 119

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	
	set @process = 'CW-7699 Alter procedure ccspRepAgentNotReadyDet'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccspRepAgentNotReadyDet] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE
	FROM RepAgentNotReadyDet
	WHERE startDate >= @from AND startDate < @to;

	WITH notReadyDetail
	AS (
		SELECT user_id, DATEADD(s, - tstatus, fecha) AS fechaInicio, fecha, tStatus, separado, TipoNotReady_id		
		FROM ccLogAgentesNotReady
		WHERE DATEADD(s, - tstatus, fecha) >= @from AND DATEADD(s, - tstatus, fecha) < @to
		)
	INSERT INTO RepAgentNotReadyDet
	SELECT convert(DATE, fechaInicio, 121) [date], isNull(usr.[Login], ''systemTranslated_NoUserName'') AS [login], xdet.user_Id AS userId, isNull(usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno + '' '' + usr.Nombres, 
			''systemTranslated_NoName'') AS [user], xdet.TipoNotReady_id AS tiponotreadyId, isNull(tn.Descripcion, ''systemTranslated_NoStatus'') AS [status], fechaInicio AS startDate, fecha AS endDate, tStatus AS 
		statusTime, tStatus AS statusTimeSeconds, datepart(yyyy, fechaInicio) [year], datepart(mm, fechaInicio) [mounth], datepart(dd, fechaInicio) [day], datepart(hh, fechaInicio) [hour], datepart(mi, fechaInicio) 
		[minute]
	FROM notReadyDetail xdet
	LEFT JOIN ccUserView usr
		ON usr.user_id = xdet.user_id
	LEFT JOIN ccTipoNotReady tn
		ON tn.tipoNotready_id = xdet.tiponotready_id
	ORDER BY startDate
END'
	EXEC(@Sql)	


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
