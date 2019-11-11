CREATE PROCEDURE [dbo].[ccsp_CsCenterwareWS_ApiKey]
	-- Add the parameters for the stored procedure here
	@action INT
	,@apiKey VARCHAR(32) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@action = 1) -- verify API key
	BEGIN
		DECLARE @response AS INT

		SELECT @response = len(apikey)
		FROM CsCenterwareWS_ApiKey
		WHERE APIkey = @apiKey COLLATE Latin1_General_CS_AS 

		SELECT isnull(@response, '')
	END

	ELSE IF (@action = 2) -- verify setting
	BEGIN
		SELECT valor
		FROM ccSettings
		WHERE setting_id = 214
	END
END