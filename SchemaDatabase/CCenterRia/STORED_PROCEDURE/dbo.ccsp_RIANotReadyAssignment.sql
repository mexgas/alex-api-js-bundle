CREATE PROCEDURE [dbo].[ccsp_RIANotReadyAssignment]
@action smallint, --1 Consulta relacion, 2 Inserta y 3 Borrar
@CampEspId smallint = 0,
@type smallint = 0, --0 ACD y 1 Campaña
@notReadyId varchar(max) = null

AS

set nocount on

if @action = 1
	begin
		if (@type = 0)
			begin
				select TipoNotReady_id, ccTipoNotReady.[Descripcion] from ccUnavailableRelation
				left outer join ccTipoNotReady on (idUnavailable = TipoNotReady_id)
				left outer join ccInbound on (idCampACD = inbound_id)
				where type = @type
				and idCampACD = @CampEspId
			end
		else
			begin
				select TipoNotReady_id, ccTipoNotReady.[Descripcion] from ccUnavailableRelation
				left outer join ccTipoNotReady on (idUnavailable = TipoNotReady_id)
				left outer join ccCamps on (idCampACD = cam_id)
				where type = @type
				and idCampACD = @CampEspId
			end
	end
	
if @action = 2
	begin
		delete ccUnavailableRelation where [idCampACD] = @CampEspId and [type] = @type 

		insert into ccUnavailableRelation
			select value, @CampEspId, @type from fn_RIASplitDelimited (@notReadyId, '|')
	end
	
if @action = 3
	begin
		delete ccUnavailableRelation where [idCampACD] = @CampEspId and [type] = @type and
			[idUnavailable] in (select value from fn_RIASplitDelimited (@notReadyId, '|'))
	end