CREATE PROCEDURE dbo.ccsp_RIAADMPosicion
@Computer varchar(40),
@pos_id smallint,
@Tipo tinyint,
@LiveConnected tinyint=null,
@NumeroExt varchar(15)='',
@isIP bit=null
as
set nocount on

if @Tipo=1 -- Insert position
 begin
 
	if exists(select Computer from ccPosicion where Status=1 and Computer=@Computer)
	 begin
		select -3 -- Posicion en Uso
		return(0)
	 end

	-- validamos si es IP
	set @LiveConnected=case @isIP when 1 then 0 else 1 end

	if (@NumeroExt='' or @NumeroExt is null or @NumeroExt='IP') and @LiveConnected=0
		set @NumeroExt=@Computer

	if exists(select Extension from ccMonitorExt where Status=1 and (Extension=@NumeroExt or Extension=@Computer))
	 begin
		select -2 -- Extension en Uso
		return(0)
	 end

	begin tran tInsert
	declare @ext_id smallint
 	Insert into ccMonitorExt (Extension, Status, isIP) Values (@NumeroExt, 1, @isIP)
	if @@rowcount=0
		RAISERROR ('Error al insertar extension', 16, 4)

	else
		select @ext_id=scope_identity()

	Insert into ccPosicion (Computer, ext_id, tipoConexion) Values(@Computer, @ext_id, @LiveConnected)
	if @@rowcount=0
		RAISERROR ('Error al insertar posicion', 16, 4)
 	
 	-- En caso de exito seleccionar 0
 	select 0
 	commit tran
	return(0)
 end

declare @extToDelete as smallint

if @Tipo=2 -- Update position
 begin

	if @isIP is null
		RAISERROR ('No sedefinio el tipo de extension', 16, 4)

	if not exists(select pos_id from ccPosicion where Status=1 and pos_id=@pos_id)
		RAISERROR ('No existe la posicion', 16, 4)

 	if exists(select pos_id from ccPosicion where Status=1 and 
 	pos_id <> @pos_id and (Computer=@Computer or Computer=@NumeroExt))
	 begin
		select -3 --  Posicion en uso
		return(0)
	 end

 	declare @checkExtension as smallint
	select @checkExtension=ext_id from ccPosicion where pos_id=@pos_id

	if exists(select Extension from ccMonitorExt where status=1 and ext_id <> @checkExtension and Extension=@NumeroExt)
	 begin
		select -2 -- Extension en Uso
		return(0)
	 end
 
	-- validamos si es IP
	if @LiveConnected is null
		set @LiveConnected=case @isIP when 1 then 0 else 1 end

	begin tran tUpdate
	Update ccPosicion set computer=@Computer, tipoConexion=@LiveConnected where pos_id=@pos_id
	if @@rowcount=0
		RAISERROR ('Error al actualizar la posicion', 16, 4)

	if isnull(@checkExtension, '0')=0
	 begin
		declare @newExtension as smallint
		if @isIP=0
			set @NumeroExt=substring(replace(@NumeroExt, '.', ''), 1, 6)

 		Insert into ccMonitorExt (Extension, Status, isIP) Values (@NumeroExt, 1, @isIP)
		if @@rowcount=0
			RAISERROR ('Error al insertar extension', 16, 4)

		else
			select @newExtension=scope_identity()

		Update ccPosicion set ext_id=@newExtension where pos_id=@pos_id
		if @@rowcount=0
			RAISERROR ('Error al registrar la extension de la posicion', 16, 4)

		select 0
		commit tran tUpdate
		return(0)
	 end

	if @checkExtension <> 0
	 begin
 		if @isIP=0
			set @NumeroExt=substring(replace(@NumeroExt, '.', ''), 1, 6)

		Update ccMonitorExt set Extension=@NumeroExt, Status=1, isIP=@isIP where ext_id=@checkExtension
		if @@rowcount=0
			RAISERROR ('Error al actualizar la extension', 16, 4)
	 end

	select 0
	commit tran tUpdate
	return(0)
 end

if @Tipo=3 -- Delete position
 begin
	
	if not exists(select pos_id from ccPosicion where Status=1 and pos_id=@pos_id)
	 begin
		select -2 -- No existe la posicion
		return(0)
	 end

	declare @ext2del int
	select @ext2del=ext_id from ccPosicion where pos_id=@pos_id

	begin tran tDelete

	Update ccPosicion set Status=0 Where pos_id=@pos_id
	if @@rowcount=0 
		RAISERROR ('Error al eliminar la posicion', 16, 4)

	if isnull(@ext2del, 0)=0
	 begin
		select 0
		commit tran tDelete
		return(0)
	 end

	update ccMonitorExt set status=0 where ext_id=@ext2del
	if @@rowcount=0
		RAISERROR ('Error al eliminar la extension', 16, 4)

	select 0
	commit tran tDelete
	return(0)
 end

if @Tipo=4 -- Load Position
 begin
	declare @setting_id tinyint
	select @setting_id=valor from ccsettings where setting_id=71
	if @setting_id=0
	 begin
		select -1 -- Ninguna de las opciones habilitadas 
		return(0)
	 end

	select P.pos_id, P.Computer, E.Extension, P.tipoConexion, 
	isnull(E.isIP, case when E.Extension='IP' then 1 else 0 end) isIP
	from ccPosicion P join ccMonitorExt E on P.ext_id=E.ext_id 
	where P.Status=1 and E.Status=1 and isnull(E.isIP, case when E.Extension='IP' then 1 else 0 end)=
	case @setting_id when 1 then 0 when 2 then 1 else isnull(E.isIP, case when E.Extension='IP' then 1 else 0 end) end
	order by P.Computer 
	return(0)
 end

if @Tipo=5 and exists(select Computer from ccPosicion where Status=1 and Computer=@Computer)
 begin
	select -1 -- Nombre en Uso
	return(0)
 end

if @Tipo=6
 begin
	if not exists(select Extension from ccMonitorExt where Status=1 and Extension=@NumeroExt)
	 begin
	 	Insert into ccMonitorExt (Extension, Status) Values (@NumeroExt, 1)
		select scope_identity()
		return(0) 
	 end
	 
	select -1 -- Nombre en Uso
	return(0)
 end

return(0)
set nocount off