-- =============================================
-- Author:		<Deivid V>
-- Create date: <2015-March-23>
-- Description:	<Get's the value of the setting>
-- =============================================
CREATE PROCEDURE [dbo].[sp_getSetting]
	-- Add the parameters for the stored procedure here
	@idSetting int = 1,
	@option int = 1
AS
BEGIN
	-- Search by id
	IF @option = 1
		BEGIN
			Select value from [dbo].[settings] where id = @idSetting;
		END
END