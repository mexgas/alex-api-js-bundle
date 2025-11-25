/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Juan Jose Medina Montes
Date: 2025/11/25
Description: Sprint 5
Database: CCenterRia
Required version: 127.2
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
    SET @version = 127 --**********actualizar a 124 sin fix
    SET @versionfix = 9
    /* Actual version (use your own script to do it)*/
    EXEC @actualVersion = ccsp_getVersion 'BD'
    EXEC @actualVersionFix = ccsp_getVersion 'BDF'
    SELECT @versionALL = valor
    FROM ccsettings
    WHERE setting_id = 77;
    SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
    FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
    WHERE id = 5;
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

    ------------------------------------ BEGIN 127.20250905.0.8 ------------------------------------
    
   ------------------------------------- BEGIN JUAN MEDINA -----------------------------------------

   	SET @process = 'Drop procedure ccsp_Limpia'
	SET @sql = '
		IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_Limpia'')
		BEGIN
			DROP PROCEDURE ccsp_Limpia;
		END
	'
	EXEC(@sql);

	SET @process = 'Create procedure ccsp_Limpia'

	SET @sql = '

		CREATE PROCEDURE ccsp_Limpia @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = '''', @dato1 VARCHAR(10) = ''''
		AS
		SET NOCOUNT ON

		DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
		DECLARE @checkLd_In_ANILst SMALLINT = 0
		/***
		 4  as res lista Negra
		 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
		 3 as res Number notExists
		 1 as res Longitud invalida
		 0 as res Numero correcto
 
		***/
		SELECT @tel = dbo.limpia(@tel)

		SELECT @lon = len(@tel)

		SELECT @pais = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 104

		SELECT @cldLocal = valor
		FROM ccSettings WITH (NOLOCK)
		WHERE setting_id = 17

		SELECT @extLen = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 108

		SELECT @validateTel = valor
		FROM ccsettings WITH (NOLOCK)
		WHERE setting_id = 206

		SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213


		IF @lon > 1
		BEGIN

			IF @validateTel = 2
				BEGIN --Setting 206 only validates blacklist
		
					IF (SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)) = 1
					BEGIN
						SELECT 4 AS res, @tel AS tel --blackList
						RETURN (0)
					END
					SELECT 0 AS res, @tel AS tel

					RETURN (0)
	
			END
			IF @validateTel = 1
			BEGIN --Setting 206 para no validar longitud ni listas negras
				SELECT 0 AS res, @tel AS tel

				RETURN (0)
			END

			IF @extLen = @lon
			BEGIN -- Setting 108 validar el tamaño longitud del telefono
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList

					RETURN (0)
				END

				SELECT 0 AS res, @tel AS tel -- Extension

				RETURN (0)
			END
		END

		DECLARE @telTemp AS VARCHAR(15)

		SELECT @telTemp = @tel

		IF @pais = 1
		BEGIN ---Mexico
			IF @lon = 3 AND @tel = ''911''
			BEGIN
				SELECT 4 AS res, @tel AS tel --Lista Negra

				RETURN (0)
			END

			IF (@lon < 10)
			BEGIN
				SELECT 1 AS res, @tel AS tel --Longitud invalida

				RETURN (0)
			END

				IF EXISTS (
				SELECT 1
				FROM ccCampsExtend
				WHERE cam_id = @Camp
				  AND ZipCodeSchedule = 1
			)
			BEGIN
				IF (@dato1 = '''' OR NOT EXISTS (SELECT 1 FROM ccTimeZoneAreaCP WHERE ZipCode = LTRIM(RTRIM(@dato1))))
				BEGIN
					SELECT 6 AS res, @tel AS tel; -- No tiene codigo postal 
					RETURN (0);
				END
			END

			IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
			BEGIN
				SELECT 2 AS res, @tel AS tel --Digitos incorrectos

				RETURN (0)
			END

			IF left(@tel, 3) = ''001''
			BEGIN
				SELECT 0 AS res, @tel AS tel

				RETURN (0)
			END

			SELECT @tel = right(@tel, 10)

			IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList

				RETURN (0)
			END
	
			If (@Camp > 0 AND @checkLd_In_ANILst = 1)
			BEGIN
				If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.	
				BEGIN
					SELECT 0 AS res, @tel AS tel	
					RETURN (0)
				END

				IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
						  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
						  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
				BEGIN
					SELECT 0 AS res, @tel AS tel
					RETURN (0)
				END
				ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
						  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
						  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
				BEGIN
					SELECT 0 AS res, @tel AS tel
					RETURN (0)
				END
			END


			SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal, DEFAULT, DEFAULT)

			IF LEFT(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp AS tel --No encontrado

				RETURN (0)
			END

			SELECT 0 AS res, @tel AS tel

			RETURN (0)
		END
		ELSE IF @pais = 2
		BEGIN --Argentina 
			SET @tel = dbo.completa(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

				RETURN (0)
			END

			SELECT @tel = dbo.fnClearPhoneArg(@tel)

			IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList      
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos      
			END

			RETURN (0)
		END
		ELSE IF @pais = 3
		BEGIN --Colombia  
			IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
			BEGIN
				SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

				RETURN (0)
			END

			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList      
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 4
		BEGIN --USA 
			EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

			RETURN (0)
		END
		ELSE IF @pais = 5
		BEGIN --Chile  
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList      
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 6
		BEGIN --Venezuela    
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList      
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 7
		BEGIN --Reino Unido
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList      
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais = 8
		BEGIN --Arabia saudita   
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF (len(@tel) IN (9, 10, 11))
			BEGIN
				IF (
						SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
						) = 1
				BEGIN
					SELECT 4 AS res, @tel AS tel --blackList      
				END
				ELSE
				BEGIN
					SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

					IF left(@tel, 1) = ''E''
					BEGIN
						SELECT 3 AS res, @telTemp --Not existsFound
					END

					SELECT 0 AS res, @tel AS tel
				END
			END
			ELSE
			BEGIN
				SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
			END

			RETURN (0)
		END
		ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
		BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:España 15:Peru, 16: Panama 
			SELECT @tel = dbo.Completa_ListaNegra(@tel)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 1 AS res, @telTemp --Longitud Invalida   
			END
			ELSE IF (
					SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
					) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList      
			END
			ELSE
			BEGIN
				SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal, DEFAULT, DEFAULT)

				IF left(@tel, 1) = ''E''
				BEGIN
					SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
				END

				SELECT 0 AS res, @tel AS tel
			END

			RETURN (0)
		END
	'
	EXEC(@sql);

   ------------------------------------- END JUAN MEDINA -------------------------------------------

	------------------------------------ END 127.20250905.0.8 --------------------------------------

	
    /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
