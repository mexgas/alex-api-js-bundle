/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @versionfix = 29
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


		set @process = 'DEV2-154_FAOM_Block_Agent_Setting207 alter table ccusers'
		set @sql = 'if not exists (select * from sys.columns where name = N''isBlocked'' and Object_ID = Object_ID(N''ccusers''))
		begin
			alter table ccusers add isBlocked tinyint null
		end'
		EXEC(@sql)


		set @process = 'DEV2-154_FAOM_Block_Agent_Setting207 drop ccsp_GalateaUpdatePassword'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdatePassword'')
		begin
			DROP PROCEDURE ccsp_GalateaUpdatePassword;
		end'
		EXEC(@sql)

		set @process = 'DEV2-154_FAOM_Block_Agent_Setting207 create ccsp_GalateaUpdatePassword '
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdatePassword]
		@UserId int,
		@Login varchar(200),
		@Password varchar(200)
		as

		-- validaciones	
			if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
				begin
					select -5 as ResponseCode--el usuario no existe
					return(0)
				end

			if  @Password <> '''' 
				begin 
					Update ccUsers set Password=@Password, LastPasswordChange = GETDATE(), isBlocked=0, LoginAttempts=0 where User_id=@UserId	and Login=@Login
					select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
				end
			else
				begin 
					select -6 as ResponseCode -- la nueva contraseña es vacia
				end'
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
