CREATE FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS
BEGIN
	
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select @pais = valor from ccSettings with(nolock) where setting_id = 104
	select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17

	return dbo.Verifica2(@tel,@pais,@cldLocal)

END