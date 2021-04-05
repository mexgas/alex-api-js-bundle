/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/03/01
Description:

Database: CCenterRia
Required version: 123.14

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
SET @versionfix = 16
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
	
	    set @process = 'CW-5008 Valida si existe campo DialingMode en ccUsers'
		set @sql = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccUsers'' AND COLUMN_NAME = ''DialingMode'')
				Begin
				ALTER TABLE ccUsers 
				ADD DialingMode bit NOT NULL
				CONSTRAINT DF_ccUsers_DialingMode DEFAULT 0
				WITH VALUES
				End'
        EXEC(@sql)

set @process = 'CW-5008 se quita el sp ccsp_GalateaADMPermisos si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaADMPermisos'')
            begin
          DROP PROCEDURE ccsp_GalateaADMPermisos;
            end'
        EXEC(@sql)


	set @process = 'CW-5008 se crea sp ccsp_GalateaADMPermisos'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaADMPermisos]
@users_id varchar(255),
@Type int, -- 1.- cambia permiso, 2.- obtiene lista de permisos
@Permit int, -- 1.- Permiso de marcacion
@Value int --Valor para permiso tipo de marcacion
AS
set nocount on

If @Type = 1 --1 Update Permission DialingMode
 begin
	 if @permit = 1 --DialingMode/PreviewPro
	 begin
		 if @Value = 0
		 begin
	   			UPDATE ccUsers SET DialingMode = @Value
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
		 if @Value = 1
		 begin
	   			UPDATE ccUsers SET  DialingMode = @Value
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
		 if @Value = 2
		 begin
	   			UPDATE ccUsers SET AllowChangeDialingMode = 1
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
		 if @Value = 3
		 begin
	   			UPDATE ccUsers SET AllowChangeDialingMode = 0
				where user_id in (select value from dbo.fn_RIASplitDelimited(@users_id, '',''))
				return(0)
		 end
	end
 end

if @Type = 2 --Get Permission
begin
	return(0)
end

set nocount off

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
