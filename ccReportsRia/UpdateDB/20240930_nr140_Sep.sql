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
SET @version = 140 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
-------------------------------------------------------------------BEGIN Toño Gallardo -----------------------------------------------------------------------------
	set @process = 'KR109001 Validar vista RepViewSummary'
	set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N''RepViewSummary''))
				BEGIN
					DROP VIEW RepViewSummary;
				END;'
	EXEC(@sql)

	set @process = 'KR109001 Cambios en vista RepViewSummary'
	set @sql = 'CREATE VIEW [dbo].[RepViewSummary] AS					select 					[date]					,[login]					,[user]					,sessionTime					,loginMktTime					,logoutMktTime					,0 callTengaged					,ndTime					,NCallsOut					,NCallsIn					,NCallsCorta					,NAtend					,NNoCalif					,Available					,0 avgCallTengaged					,twrapup					,userId					,0 TypeNotReady					,'''' descripcion					,''_Time'' descripcion_time					,0 [time]					,0 transferStatus					,0 ringingTime					,0 unknownStatus					,0 otherStatus					,0 failureStatus					,0 chatTengaged					,0 undefinedTime					,0 dialingStatus					,null TipoReadyAuxiliarId					,'''' auxiliarRedy_descripcion					,''_TimeAux'' descripcion_auxiliarRedyTime_time					,0 auxiliarRedyTime					from RepAgentSummary_VersionAmatech					union					select date					,login					,[user]					,sessionTime					,loginMktTime					,logoutMktTime					,callTengaged					,ndTime					,NCallsOut					,NCallsIn					,NCallsCorta					,NAtend					,NNoCalif					,Available					,avgCallTengaged					,twrapup					,userId					,TypeNotReady					,descripcion					,descripcion_time					,time					,transferStatus					,ringingTime					,unknownStatus					,otherStatus					,failureStatus					,chatTengaged					,undefinedTime					,dialingStatus					,TipoReadyAuxiliarId					,auxiliarRedy_descripcion					,isnull(descripcion_auxiliarRedyTime_time,''_TimeAux'') as descripcion_auxiliarRedyTime_time					,auxiliarRedyTime					from RepAgentSummary'
	EXEC(@sql)

	
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
