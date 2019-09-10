/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Ernesto Rangel

		
Date: 2019/09/09
Description: 

Database: CCenterRia
Required version: 121.41

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 41
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 41
BEGIN
	BEGIN TRAN

	BEGIN TRY



	set @process = 'CW-3371 Drop PROCEDURE ccsp_AvrsSyncronization'
		
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_AvrsSyncronization'')
			begin
				DROP PROCEDURE ccsp_AvrsSyncronization;
			end'

		exec (@sql)

		SET @process = 'CW-3371 Agregar campo DNIS a consulta de SP ccsp_AvrsSyncronization'
		SET @Sql = '
			CREATE PROCEDURE [dbo].[ccsp_AvrsSyncronization] 
			@action SMALLINT, 
			@maxRecordsToTransfer INT = 10, 
			@id INT = 0
			AS
			SET NOCOUNT ON

			IF @action = 1
			BEGIN
				DECLARE @countrId INT

				SET @countrId = 1

				SELECT @countrId = valor
				FROM ccSettings
				WHERE setting_id = 104
				

				SELECT TOP (@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone, 
				cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, 0 AS cal_manual, cal_puerto, call.dni_id, fvalida, 
				cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
				CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
				dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo, 1 AS isCallRecord,isnull(dni.dni_numero,'''') as DNIS
				FROM ccCallsIn AS call
				INNER JOIN ccInbound ON ccInbound.Inbound_id = call.Inbound_id
				INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 0
				LEFT JOIN ccDNIS dni on dni.dni_id=call.dni_id
				LEFT JOIN (
					SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
					FROM ccLogTransfers
					WHERE tipo = 1
					GROUP BY cal_id, tipo
					) trans ON call.cal_id = trans.cal_id
				
				UNION
				
				SELECT TOP (@maxRecordsToTransfer) call.cal_id AS CallId, user_id AS UserId, call.cam_id AS camAcdId, cast(call.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, 
				cal_inicio, cal_telefono, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, 
				cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
				CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
				dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo, dbo.EnableCallRecord(camps.call_record, @countrId, cal_telefono) AS isCallRecord, '''' as DNIS
				FROM ccoCallsOut AS call
				INNER JOIN ccCamps camps ON camps.cam_id = call.cam_id
				INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 1
				LEFT JOIN (
					SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
					FROM ccLogTransfers
					WHERE tipo = 2
					GROUP BY cal_id, tipo
					) trans ON call.cal_id = trans.cal_id
			END
			ELSE IF @action = 2
			BEGIN
				DELETE
				FROM ccAVRSTransfer
				WHERE id = @id
			END

		'
	exec (@sql)




		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
