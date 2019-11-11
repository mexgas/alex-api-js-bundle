CREATE PROCEDURE [dbo].[ccsp_GalateaValidateActiveSession]
@userId varchar(30),
@userIp varchar(30),
@action tinyint = NULL,
@userType tinyint -- 1-Agente 2-Admin
AS
--VALIDA QUE NO EXISTA UN MISMO USUARIO CON LA MISMA SESION Y QUE
--EL SETING DE LA SESION ESTA ACTIVO.
	IF @action = 1
	BEGIN
		IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 110 and valor = 0)
		BEGIN
			IF EXISTS (SELECT * FROM ccGalateaActiveSession WHERE user_ip = @userIp) 
			BEGIN
				--SE OBTIENE EL TIPO DE USUARIO YA REGISTRADO
				IF 0 <> (
						SELECT TOP 1 ccUsers.User_id
						FROM ccUsers
						LEFT JOIN ccGalateaActiveSession 
						ON ccGalateaActiveSession.user_id = ccUsers.User_id
						where ccUsers.TipoUser_id <> @userType
						AND ccGalateaActiveSession.user_ip = @userIp
				)
				BEGIN
					SELECT cast (1 as bit) 'IpAlreadyExists' 
				END
				ELSE
				BEGIN
					SELECT cast (0 as bit) 'IpAlreadyExists' 
				END
			END
			ELSE
			BEGIN
				SELECT cast (0 as bit) 'IpAlreadyExists' 
			END
		END
		ELSE
		BEGIN
			SELECT cast (0 as bit) 'IpAlreadyExists' 
		END
	END
	--INSERTA EN LA TABLA DE SESIONES ACTIVAS EL REGISTRO DEL USUARIO ACTUAL
	IF @action = 2
	BEGIN 	
		INSERT INTO ccGalateaActiveSession VALUES (@userId, @userIp) 
	END
	--ELIMINA EN LA TABLA DE SESIONES ACTIVAS EL REGISTRO DEL USUARIO ACTUAL
	IF @action = 3
	BEGIN
		DELETE FROM ccGalateaActiveSession WHERE @userId = user_id
	END