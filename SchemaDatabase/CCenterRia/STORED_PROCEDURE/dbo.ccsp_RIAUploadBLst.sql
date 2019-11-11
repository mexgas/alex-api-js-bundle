CREATE PROCEDURE [dbo].[ccsp_RIAUploadBLst] @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(20) = NULL
AS
SET NOCOUNT ON

DECLARE @hashCalKey INT, @hashPhone BIGINT

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

	RETURN (0)
END

IF @command = 2 --Delete Number
BEGIN
	INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@telephone, 5, @idtipolista)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey
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

SET NOCOUNT OFF