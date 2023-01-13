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
SET @versionfix = 31
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

		--------------------------------BEGIN CW-7706 MARCO GARCÍA -----------------------------------------------------------------------------------------

	SET @process = 'CW-7706 delete procedure ccsp_GalateaAdminUploadBLst'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminUploadBLst'')
		BEGIN
			DROP PROCEDURE ccsp_GalateaAdminUploadBLst;
		END';
	EXEC(@sql);

	SET @process = 'CW-7706 create procedure ccsp_GalateaAdminUploadBLst'
		SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(40) = NULL, @isKolob bit=0
		AS
		DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

		SELECT @hashPhone = dbo.hashPhone(@telephone)

		IF @calKey IS NOT NULL
		BEGIN
		  SELECT @hashCalKey = dbo.hashList(@calKey)
		END

		IF @hashCalKey IS NULL
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END
		ELSE
		BEGIN
		  IF @command IN (1, 4) --LookForNumber 
			AND EXISTS (
			  SELECT idtipolista
			  FROM cclistanegra
			  WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT 1

			RETURN (0)
		  END
		END

		IF @command = 1 --Insert Number
		BEGIN
		  EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey

		  INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  VALUES (@telephone, 1, @idtipolista)

		  SELECT 200
		END

		IF @command = 2 --Delete Number
		BEGIN
		  --Check if phone number exists
			IF EXISTS(SELECT cln.Hashtel FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista)
			BEGIN
				  IF @hashCalKey IS NULL
				  BEGIN
					--Check if request is from kolob or xion
					IF(@isKolob = 1)
					BEGIN
						--Check if phone number has calKey assigned
						SELECT @hashCalKey = cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista
						IF (@hashCalKey IS NOT NULL)
						BEGIN
							SELECT CAST(-1 AS INT) --Phone number need a calkey to delete it
						END
						ELSE
						BEGIN
							INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
							VALUES (@telephone, 5, @idtipolista)

							DELETE
							FROM cclistanegra
							WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista;
							SELECT CAST(1 AS INT)
						END
					END
					ELSE
					BEGIN
						INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
						VALUES (@telephone, 5, @idtipolista)

						DELETE
						FROM cclistanegra
						WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idtipolista
					END
				  END
				  ELSE
				  BEGIN
					--Check if phone with calKey exist
					IF NOT EXISTS (SELECT cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.HashKey = @hashCalKey AND cln.idtipolista = @idtipolista)
					BEGIN
						SELECT CAST(-4 AS INT) --Phone Number with calKey not exist
					END
					ELSE
					BEGIN
						INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
						VALUES (@telephone, 5, @idtipolista)

						DELETE
						FROM cclistanegra
						WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
						IF(@isKolob = 1)
						BEGIN
							SELECT CAST(1 AS INT)
						END
					END
				  END
			END
			ELSE
			BEGIN
				SELECT CAST(-3 AS INT) --Phone Number not exist
			END
		  RETURN (0)
		END

		IF @command = 3 --Reemplaza
		BEGIN
		  INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
		  SELECT telefono, 4, @idtipolista
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  DELETE
		  FROM cclistanegra
		  WHERE idtipolista = @idtipolista

		  RETURN (0)
		END

		IF @command = 5 --Delete by idtipolista
		BEGIN
		  UPDATE ccTiposListaNegra
		  SET STATUS = 0
		  WHERE idtipolista = @idtipolista

		  DELETE ccAgendaListaNegra
		  WHERE idagenda IN (
			  SELECT idagenda
			  FROM ccAgenda_TipolistaNegra
			  WHERE idtipolista = @idtipolista
			  )

		  DELETE ccAgenda_TipolistaNegra
		  WHERE idtipolista = @idtipolista

		  DELETE cccalifblacklist
		  WHERE idtipolista = @idtipolista

		  DELETE Camplistanegra
		  WHERE idtipolista = @idtipolista

		  DECLARE @telefono VARCHAR(10)

		  WHILE EXISTS (
			  SELECT telefono
			  FROM ccListaNegra
			  WHERE idtipolista = @idtipolista
			  )
		  BEGIN
			SELECT TOP 1 @hashPhone = Hashtel, @telefono = telefono
			FROM ccListaNegra
			WHERE idtipolista = @idtipolista

			INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
			VALUES (@telefono, 5, @idtipolista)

			DELETE
			FROM cclistanegra
			WHERE Hashtel = @hashPhone AND idtipolista = @idtipolista
		  END

		  RETURN (0)
		END

		SET NOCOUNT OFF'

	EXEC(@sql);

	--------------------------------END CW-7706 MARCO GARCÍA -----------------------------------------------------------------------------------------

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
