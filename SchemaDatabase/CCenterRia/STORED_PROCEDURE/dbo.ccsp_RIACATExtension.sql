CREATE PROCEDURE dbo.ccsp_RIACATExtension
@NumeroExt varchar(7)='',
@ext_id varchar(5),
@Status varchar(2)='',
@Tipo varchar(2)
AS
declare @sql nvarchar(1000)

If @Tipo=1
 begin
	SELECT ext_id, Extension, Status from ccMonitorExt where ext_id>0 order by ext_id
	return(0)
 end

if @Tipo=2
 begin
	if exists(select Extension from ccMonitorExt where Status=1 and Extension=@NumeroExt)
		select 1, 'Nombre en Uso'
	else if exists(select Extension from ccMonitorExt where Status=0 and Extension=@NumeroExt)
		update ccMonitorExt set Status=1 where Extension=@NumeroExt
	else
		Insert ccMonitorExt (Extension, Status) select @NumeroExt, 1

	return(0)
end

if @Tipo=4
 begin
	Update ccMonitorExt SET Extension=case @NumeroExt when '' then Extension else @NumeroExt end,
	Status=case @Status when '' then Status else @Status end where ext_id=cast(@ext_id as int)
	return(0)
 end

if @Tipo=3
 begin
	if exists(select ext_id from ccPosicion where Status=1 and ext_id=@ext_id)
	 begin
		select 1, 'Existen Posiciones utilizando esta Extension'
		return(0)
	 end

	if exists( select ext_id from ccTeclaExtensionPuerto where ext_id=@ext_id)
	 begin
		select 2, 'Existen Teclas utilizando esta Extension'
		return(0)
	 end

	update ccMonitorExt set Status=0 Where ext_id=@ext_id
	return(0)
 end