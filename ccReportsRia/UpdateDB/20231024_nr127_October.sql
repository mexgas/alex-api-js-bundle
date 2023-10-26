SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 127

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	-----------------------------------------------------BEGIN Rod Salazar -----------------------------------------------------------------

	set @process = 'CW-8143 Agregar columna nueva a reporte RepOutManagementBase'
	set @sql='
	if not exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''RepOutManagementBase'' AND COLUMN_NAME = ''campaignId'')
	begin
		alter table RepOutManagementBase add campaignId int null
	end'
	EXEC(@sql)

	set @process = 'CW-8143 Actualizar valor de columna campaignId en tabla RepOutManagementBase'
	set @sql='
	if exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''RepOutManagementBase'' AND COLUMN_NAME = ''campaignId'')
	begin
		update RepOutManagementBase 
		set campaignId = ISNULL(c.cam_id, 0)
		from RepOutManagementBase rep
		left join cccamps c on rep.Campaigns = c.cam_descripcion
	end'
	EXEC(@sql)

	set @process = 'CW-8143 Borrar sp ccspRepOutManagementBase'
	set @sql='
	if exists(select * from sys.procedures where name = ''ccspRepOutManagementBase'')
	begin
		DROP PROCEDURE ccspRepOutManagementBase
	end'
	EXEC(@sql)

	set @process = 'CW-8143 Crear sp ccspRepOutManagementBase'
	set @sql='
	
	CREATE PROCEDURE [dbo].[ccspRepOutManagementBase] @action AS TINYINT
		,@from AS DATETIME = NULL
		,@to AS DATETIME = NULL
	AS
	SET NOCOUNT ON

	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	IF @action = 1
	BEGIN
		DELETE
		FROM RepOutManagementBase
		WHERE [date] >= @from
			AND [date] < @to

		INSERT INTO RepOutManagementBase (
			DATE
			,dialResultCode
			,dialResultId
			,dialResult
			,dispositionId
			,disposition
			,subDispositionId
			,subDisposition
			,total
			,Agent
			,Campaigns
			,year
			,month
			,day
			,hour
			,minutes
			,calKey
			,telephone
			,campaignId
			)
		SELECT fecha AS [date]
			,logdial.callout_id AS dialResultCode
			,logdial.tipoResDial_id AS dialResultId
			,ISNULL(resdial.descripcion, '''') AS dialResult
			,ISNULL(tipocal.calif_id, 0) AS dispositionId
			,ISNULL(tipocal.Description, '''') AS disposition
			,ISNULL(tiposubcal.califSub_id, 0) AS subDispositionId
			,ISNULL(tiposubcal.califSubDesc, '''') AS subDisposition
			,1 AS Total
			,ISNULL(cUser.LOGIN, '''') AS Agent
			,ISNULL(ccCamps.cam_descripcion, '''') AS Campaigns
			,DATEPART(yyyy, fecha) AS [year]
			,DATEPART(mm, fecha) AS [month]
			,DATEPART(dd, fecha) AS [day]
			,DATEPART(hh, fecha) AS [hour]
			,DATEPART(mi, fecha) AS [minutes]
			,ISNULL(logdial.cal_Key, '''') AS cal_key
			,ISNULL(logdial.Telefono, '''') AS cal_telefono
			,ISNULL(cccamps.cam_id, 0) as campaignId
		FROM ccoLogDials logdial WITH (NOLOCK)
		LEFT JOIN cctipoResultadodial resdial ON logdial.tipoResDial_id = resdial.tipoResDial_id
		LEFT JOIN ccoCallsOut cout ON cout.cal_id = logdial.cal_id
		LEFT JOIN cctipocalifout tipocal ON cout.calif_id = tipocal.calif_id
		LEFT JOIN cctipocalifsubout tiposubcal ON cout.califSub_id = tiposubcal.califSub_id
		LEFT JOIN ccUserView cUser ON cUser.User_id = cout.User_id
		LEFT JOIN ccCamps ON ccCamps.cam_id = logdial.cam_id
		WHERE fecha BETWEEN @from
				AND @to
	END'
	EXEC(@sql)

	-----------------------------------------------------END Rod Salazar -----------------------------------------------------------------

	
	
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
