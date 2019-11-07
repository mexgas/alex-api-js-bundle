CREATE PROCEDURE [dbo].[ccsp_RIAGetDataFields]
@Command tinyint

AS

if ( @Command = 1 )
begin
	Select count(*) from ccoDatos 
end

if ( @Command = 2 )
begin
	Select id, Nombre from ccoDatos 
end

if ( @Command = 3 )
begin
	select valor from ccSettings where setting_id = 75
end