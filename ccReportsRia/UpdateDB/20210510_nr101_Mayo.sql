SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 101

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'Alter Colums'
		SET @sql = '
	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''RepOutDialDetail'' and COL.name = ''callKey'') < 40
	BEGIN
		ALTER TABLE RepOutDialDetail ALTER COLUMN callKey VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length 
			From sys.columns COL 
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id 
			where TAB.name = ''RepSpecialCallKeyHistory'' and COL.name = ''callKey'') < 40
	BEGIN
		ALTER TABLE RepSpecialCallKeyHistory ALTER COLUMN callKey VARCHAR (40) NOT NULL
	END'
		EXEC(@sql)

		set @process = 'CW-4384 DROP SP ccspRepOutManagementBase'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepOutManagementBase'')
		begin
			DROP PROCEDURE ccspRepOutManagementBase;
		end'
	EXEC(@sql)

	set @process = 'CW-4384 Create SP ccspRepOutManagementBase'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspRepOutManagementBase] 
	@action AS TINYINT,
	@from AS DATETIME = null,
	@to AS DATETIME = null
	AS

	SET NOCOUNT ON

	IF @from IS NULL
		SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

	IF @to IS NULL
		SELECT @to = getdate()

	IF @action = 1
	BEGIN

		IF OBJECT_ID(''tempdb..#TempRepOutManagementBase'') IS NOT NULL DROP TABLE #TempRepOutManagementBase

		create table #TempRepOutManagementBase(date datetime, dialResultCode int,dialResultId int,dialResult varchar(50),dispositionId int,
		disposition varchar(50),subDispositionId int,subDisposition varchar(50),total int,Agent varchar(100),Campaigns varchar(100)
		,[year] int,[month] int, [day] int ,[hour] int,[minutes] int
		,cal_id int, cal_telefono varchar(50),cal_key varchar(40)
		)

		create index IX_#TempRepOutManagementBase_I ON #TempRepOutManagementBase(cal_id)
	
		insert INTO #TempRepOutManagementBase
		SELECT fecha AS [date], 
		   logdial.callout_id AS dialResultCode, 
		   logdial.tipoResDial_id AS dialResultId, 
		   ISNULL(resdial.descripcion, '''') AS dialResult,       
		   ISNULL(tipocal.calif_id, 0) AS dispositionId, 
		   ISNULL(tipocal.Description, '''') AS disposition, 
		   ISNULL(tiposubcal.califSub_id, 0) AS subDispositionId,       
		   ISNULL(tiposubcal.califSubDesc, '''') AS subDisposition, 
		   1 AS Total, 
		   ISNULL(cUser.LOGIN, '''') AS Agent, 
		   ISNULL(ccCamps.cam_descripcion, '''') AS Campaigns
		   ,DATEPART(yyyy,fecha) AS [year]
		   ,DATEPART(mm, fecha) AS [month]
		   ,DATEPART(dd, fecha) AS [day]
		   ,DATEPART(hh, fecha) AS [hour]
		   ,DATEPART(mi, fecha) AS [minutes]
		   ,logDial.cal_id,
		   ISNULL(logdial.Telefono,'''') AS cal_telefono,
		   ISNULL(logdial.cal_Key,'''') AS cal_key	   	   
	FROM ccoLogDials logdial with(nolock)
		 LEFT JOIN cctipoResultadodial resdial ON logdial.tipoResDial_id = resdial.tipoResDial_id
		 LEFT JOIN ccoCallsOut cout ON cout.cal_id = logdial.cal_id
		 LEFT JOIN cctipocalifout tipocal ON cout.calif_id = tipocal.calif_id
		 LEFT JOIN cctipocalifsubout tiposubcal ON cout.califSub_id = tiposubcal.califSub_id
		 LEFT JOIN ccUsers cUser ON cUser.User_id = cout.User_id
		 LEFT JOIN ccCamps ON ccCamps.cam_id = logdial.cam_id
		 WHERE fecha BETWEEN @from AND @to


		UPDATE A
		SET A.Agent = isnull(cUser.LOGIN, ''''), A.cal_id = cout.cal_id		
		FROM #TempRepOutManagementBase A
		INNER JOIN (
			SELECT A.cal_id, callout_id, User_id
			FROM ccoCallsOut A
			LEFT JOIN #TempRepOutManagementBase B ON A.cal_id = B.cal_id
			WHERE cal_Inicio BETWEEN @from
					AND @to AND B.cal_id IS NULL
			) cout ON A.dialResultCode = cout.callout_id
		inner JOIN ccUsers cUser ON cUser.User_id = cout.User_id
		WHERE A.cal_id IS NULL

		DELETE	FROM RepOutManagementBase WHERE [date] >= @from AND [date] < @to

		INSERT INTO RepOutManagementBase
								(DATE, 
								 dialResultCode, 
								 dialResultId, 
								 dialResult, 
								 dispositionId, 
								 disposition, 
								 subDispositionId, 
								 subDisposition, 
								 total, 
								 Agent, 
								 Campaigns, 
								 year, 
								 month, 
								 day, 
								 hour, 
								 minutes,
								 calKey,
								 telephone
								)
		   SELECT DATE, 
				  dialResultCode, 
				  dialResultId, 
				  dialResult, 
				  dispositionId, 
				  disposition,
				  subDispositionId,
				  subDisposition,
				  Total, 
				  Agent, 
				  Campaigns, 
				  year, 
				  month, 
				  day, 
				  hour, 
				  minutes,
				  cal_Key,
				  cal_telefono
		   FROM #TempRepOutManagementBase

		IF OBJECT_ID(''tempdb..#TempRepOutManagementBase'') IS NOT NULL DROP TABLE #TempRepOutManagementBase
	END'
	EXEC(@sql)
		

		IF @actualVersion = @version - 1
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

