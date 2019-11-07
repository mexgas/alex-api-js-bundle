CREATE procedure [dbo].[ccsp_RIAGetEnabledServices]
as
set nocount on

SELECT
--services
case setting_id
	when 145 then 1 --chat
	when 155 then 2 --email
end [serviceId], 1 [enabled]
FROM ccsettings with(nolock)
where setting_id in (145,155) --filter: chat,email
and valor > 0 --enabled only

set nocount off