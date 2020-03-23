CREATE FUNCTION [dbo].[ValidateBlackListPhoneByList] (@tel VARCHAR(32), @calKey VARCHAR(20),@blackListId varchar(100))
RETURNS BIT
AS
BEGIN
	DECLARE @isBlackPhone BIT
	--PARA LA VALIDACION DE LISTAS NEGRAS CON HASH
	DECLARE @hasTelefono BIGINT

	if @tel is null or @tel =''
		return 1 --No tiene valor

	SELECT @hasTelefono = dbo.hashPhone(@tel)	

	DECLARE @hasCalKey BIGINT

	IF @calKey IS NOT NULL OR @calKey <> ''
		SELECT @hasCalKey = dbo.hashList(@calKey)

	SET @isBlackPhone = 0

	IF EXISTS (
			SELECT a1.idtipolista
			FROM cclistanegra a1
			INNER JOIN 
			dbo.fn_RIASplitDelimited(@blackListId,',') b ON a1.idtipolista = b.Value						
			WHERE a1.Hashtel = @hasTelefono AND (a1.HashKey IS NULL OR a1.HashKey = @hasCalKey)
			)
		SET @isBlackPhone = 1

	RETURN @isBlackPhone
END