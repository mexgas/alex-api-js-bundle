CREATE PROCEDURE [dbo].[ccsp_IVRGetEspecialidadByDnis] 
@sDnis varchar (40),
@sAni varchar (19) = null
AS
set nocount on
-- Agregamos variables
declare @inbound_id integer, @nMaxQue smallint

set @nMaxQue=0
set @inbound_id=0

if @sDnis =  ''
	set @inbound_id = 0
else
	select @inbound_id = inbound_id from ccInboundDnis where dni_id in (select dni_id from ccDnis where dni_numero like @sDnis)


if @inbound_id >0 begin
	select @nMaxQue = nMaxQue from ccInbound where inbound_id = @inbound_id
	
	-- Verificamos si el Dnis no esta bloqueado
	if exists (select dni_id from ccDnis where dni_status=1 and dni_isBlock=1 and dni_numero = @sDnis) begin
		select -1 inbound_id, @nMaxQue nMaxQue
		return(0)
	end

	-- Valida si el ani esta en lista negra
	if @inbound_id>0 and  
		exists(select telefono from ACDlistanegra A join ccListaNegra L on A.idtipolista = L.idtipolista where A.status=1 and telefono=@sAni and inbound_id=@inbound_id) begin
		select -1 inbound_id, @nMaxQue nMaxQue
		return(0)
	end

end 

select isNull(@inbound_id, 0) as inbound_id, 0 'is900', @nMaxQue nMaxQue
return(0)

set nocount off