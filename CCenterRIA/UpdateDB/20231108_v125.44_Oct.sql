/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 44
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	-----------------------------------------------------BEGIN JCL ----------------------------------------------------------------
	SET @process = ' CW-8153 alter sp ccsp_RIACampsManualCall'
	SET @sql = '
			ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			@option int,
			@UserID int = 0,
			@onChat int = 0,
			@campId int = 0
			AS
			set nocount on
			if(@option = 1)
			begin
				if (@onChat = 0)
				begin
					declare @mod smallint
					declare @IdArea smallint
					declare @DialingMode tinyint
					select @IdArea = IDArea, @DialingMode = DialingMode from ccUsers where User_id = @UserID
					select @mod = defCampaing from ccRIACat_Areas A
					where A.IDArea = @IdArea 
					select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id, c.cam_ModoManual, 
					isnull(c.selectRotativeANI, 0) selectRotativeANI
					, isnull(c.CampType,0) as CampType,
					CASE WHEN @DialingMode = 1 THEN (select count(1) from ccoWorkingTable nolock where cam_id = c.cam_id) ELSE 0 END AS countJobs,
					isnull(c.timesPreview, 0) timesPreview
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id and c.IDArea = @IdArea
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID  
						and cam_ModoManual = case when @DialingMode = 1 OR (@DialingMode = 0 AND cam_ModoManual in (1,3)) then cam_ModoManual else -1 end AND CampType = CASE WHEN @DialingMode = 1 THEN 6 ELSE CampType END
					order by cam_descripcion
				end
				else 
				begin 
					select distinct c.cam_id, c.cam_descripcion,  g.graphic_id,  c.cam_ModoManual
					, isnull(c.CampType,0) as CampType
					from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
					join ccRIACampsGraph g ON g.cam_id = c.cam_id
					where ca.user_id = @UserID and manualCallOnChat = 1
					order by cam_descripcion
					SET NOCOUNT OFF;
				end
			end
			if(@option = 2)
			begin
				declare @aniList int 
				declare @rotativeAniListId int
				select @aniList = id_anilist, @rotativeAniListId  = rotativeAlgo from ccCamps where cam_id = @campId
				if @rotativeAniListId >0 begin
					select telAni from ccRotativeANIListDetail where id_RAniList = @aniList
				end
				else begin
					select top 0 '''' telAni 
				end					
			end'
	EXEC(@sql);
	-----------------------------------------------------END JCL ----------------------------------------------------------------


	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END