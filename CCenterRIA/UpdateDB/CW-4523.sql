/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/11/10
Description:

Database: CCenterRia
Required version: 123.12

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 12
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

				set @process = 'se quita sp si existe'
				set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminWorkgroups'')
				    begin
					DROP PROCEDURE ccsp_GalateaAdminWorkgroups;
				    end'
				EXEC(@sql)
		
				set @process = 'se agrega sp ccsp_GalateaAdminWorkgroups'
				set @sql = '
					   
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null
AS
BEGIN
	IF @Option = 1
	BEGIN 
		SELECT @AdminId = ISNULL(@AdminId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
		JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
		WHERE User_id = @AdminId
					
	END
	IF @Option = 2
	BEGIN 
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id,
				WGName Name,
				StatusWorkGroup Status  
		FROM 
		ccRIACat_WorkGroup wg 
		WHERE IDWG = @WorkgroupId
					
	END

	IF @Option = 3 --Lista de wg 
	BEGIN 
	
		SELECT cast(IDWG as int) IDWG,WGName
		FROM ccRIACat_WorkGroup 
					
	END

	IF @Option = 4 --Lista de wg por area
	BEGIN 
		SELECT @idArea = ISNULL(@idArea, 0)	

		SELECT CAST(IDWG as int) IDWG 
		FROM 
		ccRIAAreaWorkGroup
		WHERE IDArea = @idArea
					
	END

	if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @WorkgroupId
				return(0)
			 end

		 	if @WorkgroupId=1
			 begin
			 set @WorkgroupId = -1
				select @WorkgroupId
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @WorkgroupId = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
			select @WorkgroupId
			return(0)
		 end

END'

		EXEC(@sql)


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
