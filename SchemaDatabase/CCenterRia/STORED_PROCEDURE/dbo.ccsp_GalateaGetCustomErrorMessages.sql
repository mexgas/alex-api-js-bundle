CREATE PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
@callout_id INT
AS
DECLARE @disconnectCause AS VARCHAR(250)
--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTA ACTIVO
declare @today datetime
declare @logDial_id int




IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
BEGIN
	--VERIFICA SI EL CALLOUT_ID EXISTE
	IF @callout_id IS NOT NULL
	BEGIN

		select @today =convert(datetime, convert(varchar(11),getdate(),121),121)

		--SE OBTIENE EL MESAJE DE ERROR DEL CARRIER A TRAVES DEL CALLOUT_ID
		SELECT top 1 @disconnectCause=disconnectCause,@logDial_id=logDial_id
		FROM ccoLogDials
		WHERE callout_id = @callout_id and fecha>=@today
		order by logDial_id desc

		WHILE PATINDEX('%[^0-9]%',@disconnectCause) <> 0
		BEGIN
		    --ELIMINA LAS LETRAS PARA DEJAR SOLO NUMEROS
		    SET @disconnectCause = STUFF(@disconnectCause,PATINDEX('%[^0-9]%',@disconnectCause),1,'')
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
			IF @disconnectCause IS NULL
			BEGIN
				SELECT 'ERROR_NOT_FOUND' 'message_description'
			END
			ELSE
			BEGIN
				--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA UNO ASOCIADO AL COIGO DE ERROR
				SELECT message_description
				FROM ccGalateaCustomErrorMessages
				WHERE message_id = 'DEFAULT'
			END
		END
	END
	ELSE
	BEGIN
		--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA EN CCOLOGDIALS EL CALLOUT_ID
		SELECT message_description
		FROM ccGalateaCustomErrorMessages
		WHERE message_id = 'DEFAULT'
	END
END
ELSE
BEGIN
	--REGRESA UN MENSAJE PREDETERMINADO PARA INFORMAR QUE EL SETTING ESTE DESHABILITADO
	SELECT 'SETTING_DISABLED' 'message_description'
END