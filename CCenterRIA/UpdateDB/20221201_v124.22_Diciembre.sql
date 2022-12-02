/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/12/01
Description: Changes for K018000 Transfer Numbers

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
SET @versionfix = 22
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
	
		set @process = 'MACL K018000 Deleting SP ccsp_GalateaAdminTransferNumbersCRUD if exists'
	    set @sql = 'if exists (select * from sys.procedures where name =''ccsp_GalateaAdminTransferNumbersCRUD'')
			begin
				DROP PROCEDURE ccsp_GalateaAdminTransferNumbersCRUD
			end'

		EXEC(@sql)

		set @process = 'MACL K018000 Creating SP ccsp_GalateaAdminTransferNumbersCRUD'
	    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminTransferNumbersCRUD]
			@Type SMALLINT,
			@IDArea SMALLINT = -1,
			@Nombre VARCHAR(50) = NULL,
			@Tel VARCHAR(50) = NULL,
			@AllowConference bit = 0,
			@NumTraId SMALLINT = NULL
			AS
			BEGIN
				IF (@type = 1) -- Read Transfer Numbers
				BEGIN
					SELECT telTransfer.numtra_id,
						   telTransfer.nombre,
						   telTransfer.tel,
						   telTransfer.allowsConference,
						   telTransfer.IDArea
					FROM dbo.telefonosTransferencia AS telTransfer
					WHERE telTransfer.idArea IN (@IDArea,-1)
					RETURN 0;
				END;

				IF (@type = 2) -- CREATE Transfer Number
				BEGIN
					DECLARE @resultCreate SMALLINT = -1 -- -1:Name in use -2:Number alredy registered
					IF NOT EXISTS(SELECT tel FROM telefonosTransferencia WHERE tel = @Tel)
					BEGIN
						IF NOT EXISTS(SELECT numtra_id FROM telefonosTransferencia WHERE nombre = @Nombre)
						BEGIN
							INSERT INTO telefonosTransferencia (nombre, tel, IDArea, allowsConference) 
							VALUES (@Nombre, @Tel, @idArea, @AllowConference)
							SELECT @resultCreate = SCOPE_IDENTITY() 
						END
					END
					ELSE
					BEGIN
						SET @resultCreate = -2
					END
		
					SELECT @resultCreate AS [result]
					RETURN(0)
				END;

				IF (@type = 3) -- UPDATE Transfer Number
				BEGIN
					DECLARE @resultEdit int = -1 -- -1:Name in use -2:Number alredy registered
					IF NOT EXISTS(SELECT tel FROM telefonosTransferencia WHERE tel = @Tel AND numtra_id <> @NumTraId)
					BEGIN
						IF NOT EXISTS(SELECT numtra_id FROM telefonosTransferencia WHERE nombre = @Nombre AND numtra_id <> @NumTraId)
						BEGIN
							UPDATE telefonosTransferencia SET
							nombre = @Nombre, 
							tel = @Tel, 
							IDArea = @IDArea, 
							allowsConference = @AllowConference
							WHERE numtra_id = @NumTraId
							SELECT @resultEdit = @@ROWCOUNT
						END
					END
					ELSE
					BEGIN
						SET @resultEdit = -2
					END
		
					SELECT @resultEdit AS [result]
					RETURN(0)
				END;
				IF (@type = 4) -- DELETE Transfer Number
				BEGIN
					DELETE FROM telefonosTransferencia WHERE numtra_id = @NumTraId
					SELECT @@ROWCOUNT AS [result]
					RETURN(0)
				END;
				IF (@type = 5) -- UPDATE Transfer Number Conference
				BEGIN
					UPDATE telefonosTransferencia SET allowsConference = @AllowConference
					WHERE numtra_id = @NumTraId
					SELECT @@ROWCOUNT AS [result]
					RETURN(0)
				END;
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