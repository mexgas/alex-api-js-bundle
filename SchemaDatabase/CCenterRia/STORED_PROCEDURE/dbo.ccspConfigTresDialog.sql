CREATE PROCEDURE ccspConfigTresDialog
	@tresDialog smallint = NULL OUTPUT
AS

	SET @tresDialog=null
	SELECT @tresDialog= valor FROM ccSettings WHERE setting_id = 13


IF (@tresDialog is NULL)
BEGIN
	SELECT @tresDialog = 5
END
-- SELECT @tresDialog
RETURN @tresDialog