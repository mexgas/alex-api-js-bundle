CREATE PROCEDURE ccspConfigTresRing 
	@tresRing smallint = NULL OUTPUT
AS

	SET @tresRing = NULL
	SELECT @tresRing= valor FROM ccSettings WHERE setting_id = 14


IF (@tresRing is NULL)
BEGIN
	SELECT @tresRing = 3
END
-- SELECT @tresRing
RETURN @tresRing