CREATE FUNCTION [dbo].[VerificaMex] (@tel VARCHAR(32))
RETURNS VARCHAR(32)
AS
BEGIN
	DECLARE @ld VARCHAR(7), @cldLocal VARCHAR(7)
	DECLARE @lon TINYINT
	DECLARE @result TINYINT
	DECLARE @mod VARCHAR(10)
	DECLARE @Cadena VARCHAR(32)
	DECLARE @isLocal BIT

	SELECT @lon = len(@tel), @mod = ''

	IF @lon < 10
	BEGIN
		RETURN 'E_' + @tel
	END

	SELECT @cldLocal = valor
	FROM ccSettings WITH (NOLOCK)
	WHERE setting_id = 17

	SELECT @tel = right(@tel, 10)

	SELECT @lon = len(@tel)

	IF @lon = 10
	BEGIN
		IF EXISTS (
				SELECT TOP 1 cld
				FROM series NOLOCK
				WHERE cld = left(@tel, 2)
				)
			SELECT @ld = left(@tel, 2)
		ELSE IF EXISTS (
				SELECT TOP 1 cld
				FROM series NOLOCK
				WHERE cld = left(@tel, 3)
				)
			SELECT @ld = left(@tel, 3)
		ELSE
			RETURN 'E_' + @tel

		SELECT TOP 1 @mod = modalidad
		FROM series NOLOCK
		WHERE cld = @ld AND serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) AND right(@tel, 4) BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

		IF @mod NOT IN ('FIJO', 'MPP', 'CPP')
		BEGIN
			RETURN 'E_' + @tel
		END

		SET @isLocal = 0

		IF EXISTS (
				SELECT *
				FROM ccRiaArecode
				WHERE area = @ld
				)
		BEGIN
			SET @isLocal = 1
		END
		ELSE IF @cldLocal = @ld
		BEGIN
			SET @isLocal = 1
		END

		SELECT @tel = CASE WHEN @mod IN ('FIJO', 'MPP') THEN CASE WHEN @isLocal = 1 THEN right(@tel, 10 - len(@ld)) ELSE '01' + @tel END --Casa
				WHEN @mod = 'CPP' THEN CASE WHEN @isLocal = 1 THEN '044' + @tel ELSE '045' + @tel END END --Celular
	END
	ELSE IF @lon > 0
	BEGIN
		SET @tel = 'E_' + @tel
	END

	RETURN @tel
END