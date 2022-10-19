/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 14
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	 ------------------------------------------------------------ Nuxipedia ---------------------------------------------------------------------
		set @process = 'Token para acceso a la Nuxipedia'
        set @sql = '
		if not exists (select * from ccsettings where setting_id = 242)
		begin
			insert into ccSettings (setting_id, valor, descripcion, Status, tipo, detalle, description, bLoadSettings, validate) 
			values(242, ''b28fdca46ae779649012d3d9e6841ce79e9924b87bca074ffd321ad02cc76d8fc0b06195fb101ee6b728ba574cab4a07bfcd8e8bda34756474b409ba6d6d3ef4'', ''Token de acceso a Nuxipedia'', 1, ''ADM'', ''Contiene el token para el login de la nuxipedia'',''Nuxipedia access token'',1,''.{0,99}'');
		end'
		EXEC(@sql)

	------- KR022021,KR022023 ----------------------------

		SET @process = 'KR022021,KR022023_Listas_ANI_Rotativo Alter procedure ccsp_GalateaAdminRotativeANI'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
			@type SMALLINT,
			@idArea SMALLINT = NULL,
			@descriptionList VARCHAR(50) = NULL,
			@id_RAniList SMALLINT = NULL,
			@PageIndex      INT = 0,
			@PageSize       INT = 0,
			@UserId			SMALLINT = 0

		AS
		BEGIN
			SET NOCOUNT ON;

			IF (@type = 1) -- Read Rotative ANI List Catalog
			BEGIN
				SELECT cral.id_RAniList,
					   cral.description,
					   cral.idArea
				FROM dbo.ccRotativeANIList AS cral
				WHERE cral.idArea IN (@idArea,-1) 
				AND cral.id_RAniList = ISNULL(@id_RAniList, cral.id_RAniList);
				RETURN 0;
			END;
			IF (@type = 2)
			BEGIN
				SELECT * 
				FROM
					(SELECT ROW_NUMBER() OVER(ORDER BY loadDate ASC) AS RowNum,
						id_RAniList,
						telAni,
						loadDate
					FROM dbo.ccRotativeANIListDetail
					WHERE id_RAniList = @id_RAniList) tmp
				WHERE  tmp.RowNum > @PageSize * (@PageIndex - 1)
				AND tmp.RowNum <= @PageSize * @PageIndex
				RETURN 0;
			END;
			If @type=3 --Create Rotative ANI List
			begin
				declare @newANILstId SMALLINT = -1 --Name in use

				if not exists(select id_RAniList from ccRotativeANIList where description = @descriptionList)
				begin
					insert into ccRotativeANIList (description,idArea) values(@descriptionList, @idArea)
					select @newANILstId = SCOPE_IDENTITY() 
				end

				select @newANILstId as [result]
				return(0)
			end
			If @type=4 --Update Rotative ANI List
			begin
				declare @idAreaOfExistingLst smallint

				select @idAreaOfExistingLst = idArea from ccRotativeANIList where id_RAniList = @id_RAniList
				if(@idAreaOfExistingLst = -1 and @idArea <> @idAreaOfExistingLst)   --Changing from global to particular idArea
				begin
					if exists(select cam_id from ccCamps where IDArea <> @idArea and id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
					begin
						select -2 as [result] --Cant change idArea cause the ANI list is related to camps on other IDArea
						return(0)
					end
				end

				if exists(select id_RAniList from ccRotativeANIList where [description] = @descriptionList and id_RAniList <> @id_RAniList)
				begin
					SELECT -1 as [result] --Name in use
					return(0)
				end
        
				update ccRotativeANIList set [description] = @descriptionList, idArea = @idArea where id_RAniList = @id_RAniList
				SELECT 1 as [result]
				return(0)
			end
			If @type=5 --Delete Rotative ANI List
			begin
				declare @result int = -2   --ANI list is related to campaign

				if not exists(select cam_id from ccCamps where id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
				begin
					delete ccRotativeANIListDetail where id_RAniList = @id_RAniList
					delete ccRotativeANIList where id_RAniList = @id_RAniList
					select @result = 1
				end

				select @result as [result]
				return(0)
			END
			IF (@type = 6) -- Read Rotative ANI List By Id
			BEGIN
				SELECT cral.id_RAniList,
					   cral.description,
					   cral.idArea
				FROM dbo.ccRotativeANIList AS cral
				WHERE cral.id_RAniList = @id_RAniList
				RETURN 0;
			END

			IF (@type = 7) -- Get List size
			BEGIN
				SELECT COUNT(*) AS listSize FROM dbo.ccRotativeANIListDetail WHERE id_RAniList = @id_RAniList
				RETURN 0;
			END
			IF(@type = 8) --Check if exist an other process executing
			BEGIN 
				SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isProcessExecuting FROM dbo.ccRIALoading AS crl
				WHERE crl.cam_id = @id_RAniList AND crl.state IN (0,2) AND crl.loadType = 2;
				RETURN (0);
			END
			IF(@type = 9) --Check if exist a campaign executing
			BEGIN
				SELECT CASE WHEN COUNT(cc.cam_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isCampaignExecuting   FROM dbo.ccCamps AS cc
				WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
				AND cc.cam_procesando = 1
				RETURN 0;
			END
			IF(@type = 10) --Update current Rotative ANI List loads to error
			BEGIN
				IF(@UserId = 0)
				BEGIN
					UPDATE ccRIALoading SET [state] = 4 WHERE loadType = 2 AND [state] < 3
				END
				UPDATE ccRIALoading SET [state] = 4
				WHERE loadType = 2 AND [state] < 3 AND userID = @UserId 
				SELECT CASE WHEN @@ROWCOUNT > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS LoadError
				RETURN 0;
			END
			IF(@type = 11) -- Get campaign and area by ani list id
			BEGIN
				SELECT cc.id_anilist, crg.frame, cc.cam_descripcion,crca.AreaName
				FROM dbo.ccCamps AS cc INNER JOIN dbo.ccRIACat_Areas AS crca ON crca.IDArea = cc.IDArea
				INNER JOIN dbo.ccRIACampsGraph AS crcg ON crcg.cam_id = cc.cam_id
				INNER JOIN dbo.ccRIAGraphics AS crg ON crg.graphic_id = crcg.graphic_id
				WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
			END
		SET NOCOUNT OFF

		END';

		EXEC(@sql);

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

