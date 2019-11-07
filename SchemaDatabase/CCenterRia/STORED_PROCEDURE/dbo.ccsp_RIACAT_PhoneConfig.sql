CREATE proc [dbo].[ccsp_RIACAT_PhoneConfig]
@Type tinyint, -- 1:Show #conf | 2:Add #conf | 3:Upd #conf | 4:Del #conf | 5:Add #tran | 6:Upd #tran | 7:Del #tran | 8: Show #tran
@CT_id SmallInt=0,
@Nombre varchar(50)='',
@Telefono varchar(50)='',
@IDArea smallint = 0 --parametro IDarea
as
set nocount on

BEGIN
declare @value bit

select @value = case when valor ='1' then 1 else 0 end from ccSettings where setting_id = 191

if @Type=1
 begin
	select numcon_id id, nombre name, tel number from telefonosConferencia order by nombre
	return(0)
 end

if @Type=2
 begin
	IF exists (select numcon_id from telefonosConferencia where nombre=@Nombre)
	 begin
		select -3 -- El nombre ya esta asignado
		return(0)
	 end

	IF exists (select numcon_id from telefonosConferencia where tel=@Telefono)
	 begin
		select -4 -- El telefono ya esta asignado
		return(0)
	 end

	insert into telefonosConferencia (nombre, tel) select @Nombre, @Telefono
	select SCOPE_IDENTITY() numcon_id
	return(0)
 end

if @Type=3
 begin
 	IF exists (select numcon_id from telefonosConferencia where nombre=@Nombre and numcon_id<>@CT_id)
	 begin
		select -5 -- El nombre ya esta asignado
		return(0)
	 end

 	IF exists (select numcon_id from telefonosConferencia where tel=@Telefono and numcon_id<>@CT_id)
	 begin
		select -6 -- El telefono ya esta asignado
		return(0)
	 end

	update telefonosConferencia set nombre=@Nombre, tel=@Telefono where numcon_id=@CT_id
	return(0)
 end

if @Type=4
 begin
	delete telefonosConferencia where numcon_id=@CT_id
	return(0)
 end

if @Type=5
 begin
	IF exists (select numtra_id from telefonosTransferencia where nombre=@Nombre and IDArea=@IDArea)
	 begin
		select -3 -- El nombre ya esta asignado
		return(0)
	 end

	 	IF exists (select numtra_id from telefonosTransferencia where tel=@Telefono and IDArea=@IDArea)
	 begin
		select -4 -- El telefono ya esta asignado
		return(0)
	 end

	insert into telefonosTransferencia (nombre, tel, IDArea) select @Nombre, @Telefono,@IDArea --se agrega IDArea
	select SCOPE_IDENTITY() numtra_id
	return(0)
 end

if @Type=6
 begin
 	IF exists (select numtra_id from telefonosTransferencia where nombre=@Nombre and numtra_id<>@CT_id and IDArea=@IDArea )
	 begin
		select -5 -- El nombre ya esta asignado
		return(0)
	 end

 	IF exists (select numtra_id from telefonosTransferencia where tel=@Telefono and numtra_id<>@CT_id and IDArea=@IDArea )
	 begin
		select -6 -- El telefono ya esta asignado
		return(0)
	 end

	update telefonosTransferencia set nombre=@Nombre, tel=@Telefono where numtra_id=@CT_id and IDArea=@IDArea
	return(0)
 end

if @Type=7
 begin
	delete telefonosTransferencia where numtra_id=@CT_id
	return(0)
 end

if @Type=8
 begin
	if @value = 1
	begin
		select numtra_id id, nombre name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre
	end
	else
	begin
		select numtra_id id, isnull(cast(IDArea as varchar(20) )+' - '+  nombre, nombre) name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia  order by nombre
	end
	return(0)
 end

return(0)
set nocount off
end