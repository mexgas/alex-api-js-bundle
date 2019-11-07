CREATE PROCEDURE [dbo].[ccsp_GetAgentECRelations]
@User_id smallint,@action int =0
AS
set nocount on

declare @idioma as bit, @tipo as varchar(6)

if @action=0 begin
	select distinct 'Tipo'=1, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, E.cli_id
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
	union
	select distinct 'Tipo'=2, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		order by 'Tipo'
end
else begin
	select distinct 1 tipo, E.Inbound_id, E.descripcion, A.Login, A.user_id, prioridad, skill, isnull(E.cli_id,0) cli_id
	,right('0'+cast(1 as varchar(1)),1) + right('00000'+cast(E.Inbound_id as varchar(5)),5)
	+ right('00'+cast(prioridad as varchar(2)),2) + right('00'+cast(skill as varchar(2)),2) sPertenencias
		from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
		join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		union
	select distinct 2 tipo, C.cam_id, C.cam_descripcion, A.Login, A.user_id, prioridad, skill, C.cli_id
	,right('0'+cast(2 as varchar(1)),1) + right('00000'+cast(C.cam_id as varchar(5)),5)
	+ right('00'+cast(prioridad as varchar(2)),2) + right('00'+cast(skill as varchar(2)),2) sPertenencias
		from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
		join ccUsers A  on A.user_id = CA.user_id and A.TipoUser_id =1
		Where A.user_id = @User_id and A.status > 0
		order by 'Tipo'

end