CREATE PROCEDURE [dbo].[ccsp_RIAADMLoadSettings]
@setting_id as tinyint = 0,
@type as tinyint = null,
@ip_admin as varchar(15)=''
AS

declare @bremlog as tinyint
set nocount on
if @type is null
 begin
	select @bremlog = case when ip = @ip_admin then 1 else 0 end from ccriaremotelog where ip = @ip_admin
	IF @setting_id=0
 		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status='1' and bLoadSettings = 1 order by setting_id
	ELSE
		select setting_id, valor, isnull(@bremlog,0) ip_host from ccsettings where Status='1' and setting_id  = @setting_id
	return(0)
 end

if @type=1 -- Settings de paises
 begin
	select CtyCode, minPhoneLength, maxPhoneLength, CtyID from ccRIACat_Country
	where CtyID in (select valor from ccSettings where setting_id=104)
	return(0)
 end

set nocount off