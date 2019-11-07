CREATE PROCEDURE [dbo].[ccsp_AgentLastNotReady] 
				@user_id SMALLINT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @lastStatus TINYINT;
	DECLARE @info VARCHAR(100);

	
	SELECT @lastStatus = 0;

	SELECT TOP 1 @lastStatus = ISNULL(tipoStatusAge_id, 0)
	FROM ccLogAgentesDia 
	WHERE user_id = @user_id and tipoStatusAge_id not in(0,1)
	ORDER BY fecha DESC;

	IF @lastStatus = 2
	BEGIN
		SELECT TOP 1 tipoNotReady_Id
		FROM ccLogAgentesNotReady
		WHERE user_id = @user_id
		ORDER BY fecha DESC;
	
		RETURN( 0 );
	END;
	DECLARE @Default SMALLINT = 0
	SELECT @Default AS tipoNotReady_Id;

	SET NOCOUNT OFF;
END;