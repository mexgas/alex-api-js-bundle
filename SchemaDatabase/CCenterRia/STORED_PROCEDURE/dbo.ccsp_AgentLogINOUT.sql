CREATE PROCEDURE [dbo].[ccsp_AgentLogINOUT] @UserID SMALLINT, @Extension VARCHAR(7) = NULL, @Computer VARCHAR(20) = NULL, @TipoMov TINYINT, -- 0= LogOut,  1=LogIN,	3=Consulta
	@fecha DATETIME = NULL
AS
SET NOCOUNT ON

IF @fecha IS NULL
	SET @fecha = getdate()

DECLARE @hourlogin VARCHAR(8)
DECLARE @sessionsecs INT
DECLARE @sessiontime VARCHAR(8)
DECLARE @fecha_ini DATETIME

IF @TipoMov = 1
BEGIN
	INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
	VALUES (@UserID, @Extension, 1, @fecha)

	INSERT ccLogAgentesDia (User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callID)
	VALUES (@UserID, 0, 0, @fecha, 0, 0, 1, 0)

	UPDATE c
	SET User_id = @UserID
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion))
	WHERE Computer = @Computer

	UPDATE c
	SET user_id = 0
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
	WHERE Computer <> @Computer AND user_id = @UserId

	UPDATE ccUsers
	SET TipoStatusAge_id = 3, LastLoginAttempt = @fecha
	WHERE User_id = @UserID

	IF EXISTS (
			SELECT valor
			FROM ccSettings
			WHERE tipo = 'AGT' AND STATUS = '1' AND setting_id = '53' AND valor = 2
			)
	BEGIN
		IF NOT EXISTS (
				SELECT axLic_Desc
				FROM axLicG729_Data
				WHERE axLic_Status = 1 AND pos_id IN (
						SELECT pos_id
						FROM ccPosicion
						WHERE Computer = @Computer OR user_id = @Userid
						)
				)
		BEGIN
			RAISERROR ('Error. Without License', 18, 1)

			RETURN (0)
		END

		UPDATE axLicG729_Data
		SET axLic_Status = 2
		WHERE axLic_Status = 1 AND pos_id IN (
				SELECT pos_id
				FROM ccPosicion
				WHERE Computer = @Computer OR user_id = @Userid
				)

		SELECT '0' CPLic

		RETURN (0)
	END

	RETURN (0)
END

IF @TipoMov = 0
BEGIN
	INSERT ccLogLogIn (User_id, Extension, TipoMov, fecha)
	VALUES (@UserID, @Extension, 0, @fecha)

	UPDATE c
	SET User_id = 0
	FROM ccPosicion c WITH (INDEX (IX_ccPosicion_2))
	WHERE Computer = @Computer OR user_id = @Userid

	UPDATE ccUsers
	SET TipoStatusAge_id = 0
	WHERE User_id = @UserID

	IF EXISTS (
			SELECT valor
			FROM ccSettings
			WHERE tipo = 'AGT' AND STATUS = '1' AND setting_id = 53 AND valor = '2'
			)
	BEGIN
		UPDATE axLicG729_Data
		SET axLic_Status = 0, pos_id = NULL, fecha_log = NULL
		WHERE pos_id IN (
				SELECT pos_id
				FROM ccPosicion
				WHERE Computer = @Computer OR user_id = @Userid
				)
	END

	RETURN (0)
END

IF @TipoMov = 3
BEGIN
	SELECT @fecha_ini = convert(DATETIME, convert(VARCHAR(11), getdate()))

	SELECT @hourlogin = convert(VARCHAR(8), isnull(min(fecha), getdate()), 114)
	FROM ccLogLogin
	WHERE TipoMov = 1 AND user_id = @UserID AND fecha >= @fecha_ini

	SELECT @sessionsecs = isnull(CASE WHEN sum(convert(INT, DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) > 0 THEN sum(convert(INT, DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) ELSE sum(convert(INT, DateDiff(second, '00:00', Convert(VARCHAR(30), fecha, 14))) * (1 - 2 * tipomov)) + convert(INT, DateDiff(second, '00:00', Convert(VARCHAR(30), getdate(), 14))) END, 0)
	FROM ccLogLogin
	WHERE user_id = @UserID AND fecha > dateadd(hh, - 10, getdate())

	SELECT @sessiontime = RIGHT('0' + CONVERT(VARCHAR(6), @sessionsecs / 3600), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), (@sessionsecs % 3600) / 60), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @sessionsecs % 60), 2)

	SELECT 'HourLogin' = @hourlogin, 'SessionTime' = @sessiontime, 'SessionSecs' = @sessionsecs

	RETURN (0)
END