CREATE PROCEDURE [dbo].[ccsp_GalateaDnis]
--declare
@User varchar(10),
@Tipo tinyint,
@Dnis varchar(40) = null,
@Inbound_id smallint = null,
@dni_id as smallint = null,
@dnis_ids as varchar(MAX) = null,
@dni_description as varchar(40) = null,
@dni_isBlock as bit = null
as
set nocount on

if @Tipo = 1 -- carga dnis
 begin
	select dni_id, dni_numero as dni_number, dni_descripcion as dni_description, case when dni_id in(select dni_id from ccInboundDnis) then 1 else 0 end dni_isRelated
	from ccDnis where dni_Status=1 order by 2
	return(0)
 end

if @Tipo = 2 -- carga relaciones de dnis
 begin
	if cast(@user as smallint) > 0 and not exists (select * from ccUsers_Roles where User_id = cast(@user as smallint) and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
		select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'' as dni_number,'' as dni_description, cast(0 as tinyint) dni_isBlock
		from ccInbound a1
		inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1
		AND a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User, 2) where cam_id not in (select Inbound_id from ccInboundDnis))
		union
		select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
		from ccInboundDnis cid 
		left join ccInbound ci on ci.inbound_id = cid.inbound_id 
		join ccDnis cd on cd.dni_id = cid.dni_id 
		where cd.dni_Status=1
		order by 3,4
		return(0)
	end
	else begin
		select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'' as dni_number,'' as dni_description, cast(0 as tinyint) dni_isBlock
		from ccInbound a1
		inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and IDArea is not null and a1.Inbound_id not in (select Inbound_id from ccInboundDnis)
		union
		select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
		from ccInboundDnis cid 
		left join ccInbound ci on ci.inbound_id = cid.inbound_id 
		join ccDnis cd on cd.dni_id = cid.dni_id 
		where cd.dni_Status=1
		order by 3,4
		return(0)
	end
	return(0)
 end

if @Tipo = 3 -- Agrega Dnis
 begin
	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
	 begin
		insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
		select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
		select top(1) dni_id from ccDNIS order by dni_id desc
		return(0)
	 end
	 
	select cast(-1 as smallint)
 end

if @Tipo = 4 -- Elimina Dnis
 begin
	delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
	
	select ci.inbound_id, cd.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
	from ccInbound ci , ccDNIS cd
	where ci.Inbound_id=@Inbound_id and dni_id=@dni_id
 end

if @Tipo = 5 -- Agrega Relacion
 begin
	insert into ccInboundDnis (Inbound_id, dni_id)
	select @Inbound_Id,B.Value from  dbo.fn_RIASplitDelimited (@dnis_Ids, ',') B
	left join ccInboundDnis A on A.dni_id=B.Value 
	where  A.dni_id is null

	select cast(@Inbound_Id as smallint) inbound_id,cast(B.Value as smallint) dni_id, 
	ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock		
	,case when cid.Inbound_id is null then 0 else 1 end isAssigned
	from  dbo.fn_RIASplitDelimited (@dnis_Ids, ',') B
	left join ccInboundDnis cid on cid.dni_id=B.Value and cid.Inbound_id=@Inbound_Id
	left join ccInbound ci on ci.inbound_id = @Inbound_Id
	inner join ccDnis cd on cd.dni_id = B.Value
	order by 3,4
 end

if @Tipo = 6 -- Elimina Dnis sin pedir inbound_id
 begin
	if exists(select dni_id from ccInboundDnis where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, ',')) and isnull(inbound_id, 0) <> 0)
		select -1

	else begin
		update ccDNIS set dni_Status=0 where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, ','))--= @dni_id -- delete from ccdnis where dni_id = @dni_id
		select 1
	end
 end

if @tipo = 7
 begin
	if @Dnis = (select dni_numero from ccDNIS where dni_id=@dni_id) begin
		update ccDnis set 
		dni_Descripcion=isnull(@dni_description,dni_Descripcion)
		where dni_id = @dni_id 
		
		select 1
		return(0)
	end

	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis) begin
		update ccDnis set 
		dni_numero=case when @Dnis <> '0' then @Dnis else dni_numero end,
		dni_Descripcion=isnull(@dni_description,dni_Descripcion),
		dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
		where dni_id = @dni_id 

		select 1
		--select dni_id,dni_numero as dni_number, dni_Descripcion as dni_Descriptiondni_id, dni_isBlock from ccDNIS where dni_id=@
		return(0)
	end
	
	select -1
 end

set nocount off