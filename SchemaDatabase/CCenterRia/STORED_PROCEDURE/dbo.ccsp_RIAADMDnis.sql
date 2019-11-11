CREATE PROCEDURE dbo.ccsp_RIAADMDnis
@User varchar(10),
@Tipo tinyint,	-- 0 = Consultar, 1 = Alta, 2 = Modificacion, 3 = Borrar, 4 = Agrega Dnis, 
				-- 5 = Elimina Dnis, 6 = Agrega Relacion, 7 = Load Dnis per supervisor, 8 = elimina dnis sin pedir inbound_id, 9 = editar dnis
@Dnis varchar(40),
@Inbound_id smallint,
@dni_id as smallint,
@dni_description as varchar(40) = null,
@dni_isBlock as bit = null
as
set nocount on

if @Tipo = 0 -- Consultar
 begin
	select dni_numero from ccDnis where dni_Status=1 and dni_id=@dni_id
	return(0)
 end

if @Tipo = 1 -- Carga especialidades
 begin
	select a1.Inbound_id, descripcion from ccInbound a1
	 inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	where a3.type_id = 1
	AND a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User, 2))
	order by descripcion
	return(0)
 end

if @Tipo = 2 -- carga dnis
 begin
	select dni_id, dni_numero, dni_descripcion, cast(dni_isBlock as tinyint) dni_isBlock 
	from ccDnis where dni_Status=1 and dni_id not in(select dni_id from ccInboundDnis) order by 2
	return(0)
 end

if @Tipo = 3 -- carga relaciones de dnis
 begin
	select cid.inbound_id, cid.dni_id, ci.descripcion, cd.dni_numero, dni_descripcion, cast(dni_isBlock as tinyint) dni_isBlock
	from ccInboundDnis cid 
	 join ccInbound ci on ci.inbound_id = cid.inbound_id 
	 join ccDnis cd on cd.dni_id = cid.dni_id 
	where cd.dni_Status=1
	order by 3,4
	return(0)
 end

if @Tipo = 4 -- Agrega Dnis
 begin
	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
	 begin
		insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
		select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
		return(0)
	 end

	select 1
	return(0)
 end

if @Tipo = 5 -- Elimina Dnis
 begin
	delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
	return(0)
 end

if @Tipo = 6 -- Agrega Relacion
 begin
	if not exists(select dni_Id from ccInboundDnis where Inbound_Id = @Inbound_Id and dni_Id = @dni_Id)
	 begin
		insert into ccInboundDnis (Inbound_id, dni_id) values (@Inbound_Id, @dni_Id)
		return(0)
	 end
	 
	select 1
	return(0)
 end

if @Tipo = 7 -- Load Dnis per supervisor
 begin
	select cid.inbound_id, cid.dni_id, ci.descripcion, cd.dni_numero, cd.dni_descripcion, cast(cd.dni_isBlock as tinyint) dni_isBlock
	from ccInboundDnis cid 
	 join ccInbound ci on ci.inbound_id = cid.inbound_id 
	 join ccDnis cd on cd.dni_id = cid.dni_id 
	where cd.dni_Status=1 and ci.status = 1 and cid.inbound_id in (select cam_id from ccSupervisorCam where tipo = 0)-- and user_id = @User
	order by 3,4
	return(0)
 end

if @Tipo = 8 -- Elimina Dnis sin pedir inbound_id
 begin
	if exists(select dni_id from ccInboundDnis where dni_id = @dni_id and isnull(inbound_id, 0) <> 0)
		select -1

	else
		update ccDNIS set dni_Status=0 where dni_id = @dni_id -- delete from ccdnis where dni_id = @dni_id

	return(0)
 end

if @tipo = 9
begin
	update ccDnis set 
	dni_numero=case when @Dnis <> '0' then @Dnis else dni_numero end,
	dni_Descripcion=isnull(@dni_description,dni_Descripcion),
	dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
	where dni_id = @dni_id 
end

return(0)
set nocount off