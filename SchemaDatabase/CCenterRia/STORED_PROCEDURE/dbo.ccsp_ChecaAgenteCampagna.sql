CREATE PROCEDURE dbo.ccsp_ChecaAgenteCampagna
@AgenteID int, --ID del agente 
@Campagna smallint --ID de la campaña
AS
set nocount on
-- Verifica que un agente determinado esté asignado a la campaña indicada --

if exists(select user_id from ccCampsAgente where user_id=@AgenteID and cam_id=@Campagna)
	SELECT 1 'IsIntoCampaign'
else
	SELECT 0 'IsIntoCampaign'

set nocount off