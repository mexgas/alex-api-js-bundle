create PROCEDURE [dbo].[ccAgentStatus]
@tipo as tinyint,
@cam as smallint=0,
@inOut as bit=false,
@amount as smallint=0
AS
if @tipo = 0
begin
	select id, [type] from ccCamEspAgentStatus
end
--carga las relaciones de campañas
if @tipo = 1
begin
select cA.user_id,cA.cam_id as id, cA.idWG from cccampsagente cA, ccCamEspAgentStatus CES where cA.cam_id = CES.id and CES.type = 1
end
--carga las relaciones de especialidad
if @tipo = 2
begin
select iA.user_id,iA.inbound_id as id, iA.idWG from ccInboundAgentes iA, ccCamEspAgentStatus CES where iA.inbound_id = CES.id and CES.type = 0
end
--actualiza informacion
if @tipo = 3
begin
update ccCamEspAgentStatus set amount= @amount where id = @cam and type = @inOut
end