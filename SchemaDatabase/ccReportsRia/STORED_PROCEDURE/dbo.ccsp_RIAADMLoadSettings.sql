CREATE PROCEDURE [dbo].[ccsp_RIAADMLoadSettings]
@setting_id as tinyint = 0,
@type as tinyint = null,
@ip_admin as varchar(15)=''
AS

declare @bremlog as tinyint
set nocount on
if @type is null
 begin
	IF @setting_id=0
 		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status='1' order by setting_id
	ELSE
		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status='1' and setting_id  = @setting_id
	return(0)
 end