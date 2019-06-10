/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Jesus Gallardo
Date: 2019/04/02
Description: CW-2945


Database: ccReportsRia
Required version: 65


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 66

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		SET @process = 'CW-2945 Rename Columns '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutManagementBase] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	SELECT fecha AS DATE, logdial.callout_id AS dialResultCode, logdial.tipoResDial_id AS dialResultId, isnull(resdial.descripcion, '''') AS dialResult--
	, isnull(tipocal.calif_id, 0) AS dispositionId, ISNULL(tipocal.Description, '''') AS disposition, isnull(tiposubcal.califSub_id, 0) AS subDispositionId--
	, isnull(tiposubcal.califSubDesc, '''') AS subDisposition, 1 AS Total, isnull(cUser.LOGIN, '''') AS Agent, isnull(ccCamps.cam_descripcion, '''') AS Campaigns--
	, datepart(yyyy, CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), fecha, 121) + '':00'', 121)) AS [year] --
	, datepart(mm, CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), fecha, 121) + '':00'', 121)) AS [month]--
	, datepart(dd, CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), fecha, 121) + '':00'', 121)) AS [day]--
	, datepart(hh, fecha) AS [hour], datepart(mi, fecha) AS [minutes], logDial.cal_id
	INTO #TempRepOutManagementBase
	FROM ccoLogDials logdial
	LEFT JOIN cctipoResultadodial resdial ON logdial.tipoResDial_id = resdial.tipoResDial_id
	LEFT JOIN ccoCallsOut cout ON cout.cal_id = logdial.cal_id
	LEFT JOIN cctipocalifout tipocal ON cout.calif_id = tipocal.calif_id
	LEFT JOIN cctipocalifsubout tiposubcal ON cout.califSub_id = tiposubcal.califSub_id
	LEFT JOIN ccUsers cUser ON cUser.User_id = cout.User_id
	LEFT JOIN ccCamps ON ccCamps.cam_id = logdial.cam_id
	WHERE fecha BETWEEN @from
			AND @to

	UPDATE A
	SET A.Agent = isnull(cUser.LOGIN, ''''), A.cal_id = cout.cal_id
	FROM #TempRepOutManagementBase A
	INNER JOIN (
		SELECT A.cal_inicio, A.cal_id, callout_id, User_id
		FROM ccoCallsOut A
		LEFT JOIN #TempRepOutManagementBase B ON A.cal_id = B.cal_id
		WHERE cal_Inicio BETWEEN @from
				AND @to AND B.cal_id IS NULL
		) cout ON A.dialResultCode = cout.callout_id
	LEFT JOIN ccUsers cUser ON cUser.User_id = cout.User_id
	WHERE A.cal_id IS NULL AND cal_Inicio BETWEEN @from
			AND @to

	DELETE
	FROM RepOutManagementBase 
	WHERE [date] >= @from AND [date] < @to


	INSERT RepOutManagementBase (DATE, dialResultCode, dialResultId, dialResult, dispositionId, disposition, subDispositionId, subDisposition, total, Agent, Campaigns, year, month, day, hour, minutes)
	SELECT DATE, dialResultCode, dialResultId, dialResult, dispositionId, disposition, subDispositionId, subDisposition, Total, Agent, Campaigns, year, month, day, hour, minutes
	FROM #TempRepOutManagementBase

	DROP TABLE #TempRepOutManagementBase
END
'
		EXEC (@sql)

		


		--IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

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
