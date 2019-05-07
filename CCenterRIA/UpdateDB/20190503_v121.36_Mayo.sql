/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

Se agrega la tarea
CW-SETTNGS

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 36

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 35
BEGIN
	BEGIN TRAN
	BEGIN TRY
					
		SET @process = 'CW-2831 Alter ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
					ALTER PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
					@cal_id INT
					AS
						DECLARE @disconnectCause AS VARCHAR(250)
						--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTA ACTIVO
						DECLARE @callout_id AS INT
						IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
						BEGIN
							--VALIDA QUE EL CALLOUT_ID EXISTA EN CCOLOGDIALS
							SELECT @callout_id=callout_id FROM ccoCallsOut WHERE cal_id = @cal_id
							IF @callout_id IS NOT NULL
							BEGIN
								--SE OBTIENE EL TIPO DE USUARIO YA REGISTRADO
								SELECT @disconnectCause=disconnectCause
								FROM ccoLogDials
								WHERE callout_id = @callout_id

								WHILE PATINDEX(''%[^0-9]%'',@disconnectCause) <> 0
								BEGIN
								    --ELIMINA LAS LETRAS PARA DEJAR SOLO NUMEROS
								    SET @disconnectCause = STUFF(@disconnectCause,PATINDEX(''%[^0-9]%'',@disconnectCause),1,'''')
								END

								--VALIDA QUE EXISTA UN MENSAJE DE ERROR PARA EL CODIGO
								IF EXISTS (SELECT message_description FROM ccGalateaCustomErrorMessages WHERE message_id = @disconnectCause)
								BEGIN
									--REGRESA MENSAJE ASOCIADO AL CODIGO DE ERROR
									SELECT message_description
									FROM ccGalateaCustomErrorMessages
									WHERE message_id = @disconnectCause
								END
								ELSE
								BEGIN
									--REGRESA MENSAJE DE ERROR NO ENCONTRADO SI AL MOMENTO DE CONSULTAR NO EXISTE UN ERROR
									IF (@disconnectCause ='''')
									BEGIN
										SELECT ''ERROR_NOT_FOUND'' ''message_description''
									END
									ELSE
									BEGIN
										--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA UNO ASOCIADO AL COIGO DE ERROR
										SELECT message_description
										FROM ccGalateaCustomErrorMessages
										WHERE message_id = ''DEFAULT''
									END
								END
							END
							ELSE
							BEGIN
								--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA EN CCOLOGDIALS EL CALLOUT_ID
								SELECT message_description
								FROM ccGalateaCustomErrorMessages
								WHERE message_id = ''DEFAULT''
							END
						END
						ELSE
						BEGIN
							--REGRESA UN MENSAJE PREDETERMINADO PARA INFORMAR QUE EL SETTING EST? DESHABILITADO
							SELECT ''SETTING_DISABLED'' ''message_description''
						END
						'
		EXEC (@Sql)
		
		SET @process = ''
		SET @Sql = ''
		EXEC (@Sql)
		
	-- *********************** END 	121.03-5_20190430 *********************** ---
		
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
