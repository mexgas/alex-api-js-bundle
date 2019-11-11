CREATE PROCEDURE ccspConfigTresDelayIn
	@tresDelayIn smallint = NULL OUTPUT
AS
	set @tresDelayIn = NULL
	
	SELECT @tresDelayIn = valor FROM ccSettings WHERE setting_id = 12

IF ( @tresDelayIn is NULL)
BEGIN
	SELECT @tresDelayIn = 30
END

-- SELECT @tresDelayIn
RETURN @tresDelayIn