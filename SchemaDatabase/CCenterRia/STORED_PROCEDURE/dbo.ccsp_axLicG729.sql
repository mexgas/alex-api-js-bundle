CREATE procedure dbo.ccsp_axLicG729
@Computer varchar(20),
@logout bit=0
as
set nocount on
declare @axLic_Desc varchar(160)

if not exists(select pos_id from ccPosicion where Computer=@Computer or IP=@Computer)
 begin
	declare @ext_id smallint
 	Insert into ccMonitorExt (Extension, Status, isIP) Values (@Computer, 1, 1)
	if @@rowcount=0
		RAISERROR ('Error al insertar extension', 16, 4)

	else
		select @ext_id=scope_identity()

	Insert into ccPosicion (Computer, ext_id, tipoConexion) Values(@Computer, @ext_id, 0)
	if @@rowcount=0
		RAISERROR ('Error al insertar posicion', 16, 4)
 end

declare @pos_id int
select @pos_id=pos_id from ccPosicion where Computer=@Computer or IP=@Computer

if exists (select axLic_Desc from axLicG729_Data where pos_id=@pos_id)
 begin
 	select @axLic_Desc=axLic_Desc from axLicG729_Data where pos_id=@pos_id
 	update axLicG729_Data set fecha_log=getdate() where pos_id=@pos_id
	select @axLic_Desc CPLic
	return(0)
 end
 
select top 1 @axLic_Desc=axLic_Desc from axLicG729_Data where axLic_Status=0 and pos_id is null order by newid()

if @axLic_Desc is null
 begin
	select top 1 @axLic_Desc=axLic_Desc from axLicG729_Data where axLic_Status=1 and fecha_log<dateadd(minute, -1, getdate()) order by newid()

	if @axLic_Desc is null
	 begin
		select '-3' CPLic -- Sin licencias disponibles
		return(0)
	 end
 end

update axLicG729_Data set axLic_Status=1, pos_id=@pos_id, fecha_log=getdate() where axLic_Desc=@axLic_Desc
select @axLic_Desc CPLic
return(0)

set nocount off