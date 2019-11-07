CREATE PROCEDURE [dbo].[ccsp_RIAADMCalif]
@calif_id varchar(8000)=null,
@cam_id smallint=null,
@Type tinyint= null, -- 0=IN | 1=OUT
@command tinyInt, -- 1=Una Campaña | 2=Area
@AreaId smallint=null
AS
set nocount on

If @command=1 -- Elimina una calificacion
 begin
	delete ccCalifCamp where calif_id=@calif_id and cam_id =@cam_id and tipo=@Type
	if @Type=0 and not exists(select C.calif_id from ccCalifCamp C join ccTipoCalif T on C.calif_id = T.calif_id and T.CanReprogram=1 and C.Tipo=0 and C.cam_id=@cam_id)
	 begin
		update ccInbound set cam_id=null where Inbound_id=@cam_id
	 end
	 
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@cam_id) where cam_id=@cam_id
	return(0)
 end

If @command=2 -- Elimina calificacion de todas las camáñas o especialidades
 begin
	declare @sql as nvarchar(4000)
	set @sql='delete from ccCalifCamp where calif_id in (' + @calif_id +
	') and cam_id in (select distinct b.' + case @Type when 0 then 'inbound_id' else 'cam_id' end + 
	' as cam_id from ccCalifCamp a inner join ' + case @Type when 0 then 'ccInbound' else 'ccCamps' end + 
	' b on a.cam_id=b.' + case @Type when 0 then 'inbound_id' else 'cam_id' end + 
	' where IDArea ' + isnull('='+cast(@AreaId as varchar(10)), 'is null') + ') and tipo=' + CAST(@Type as char(1))
	execute sp_executesql @sql

	if @Type=0
	 begin
 		set @sql='update ccinbound set cam_id=null where inbound_id not in (select C.cam_id from ccCalifCamp C' +
 		' join ccTipoCalif T on C.calif_id = T.calif_id and T.CanReprogram=1 and C.Tipo=0) and inbound_id in ('+
 		' select cam_id from ccCalifCamp where Tipo=0)'
		execute sp_executesql @sql
	 end

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
 end

If @command=3 -- Verifica si de la opción uno se eliminaron todas sus calificaciones
 begin
	If exists(Select cam_id from ccCalifCamp where cam_id=@cam_id and tipo=@Type)
		return(0)

	If @Type=0
	 begin
		Update ccInbound set ShowCalifWnd=0 where inbound_id=@cam_id
		return(0)
	 end

	Update ccCamps set cam_ShowCalifWnd=0 where cam_id=@cam_id
	return(0)
 end

If @command=4 -- Verifica si de la opción dos se eliminaron todas sus calificaciones
 begin
	If @Type=0
	 begin
		Update ccInbound set ShowCalifWnd=0 where inbound_id in (select A.inbound_id from ccInbound A
		left join ccCalifCamp B on A.inbound_id=B.cam_id and B.Tipo=0
		group by A.inbound_id having count(B.cam_id)=0) and IDArea=@AreaId
		return(0)
	 end

	Update ccCamps set cam_ShowCalifWnd=0 where cam_id in (select A.cam_id from ccCamps A
	left join ccCalifCamp B on A.cam_id=B.cam_id and B.Tipo=1
	group by A.cam_id having count(B.cam_id)=0) and IDArea=@AreaId
	return(0)
 end

If @command=5 -- Elimina las calificaciones de un area
 begin
	If @Type=0
	 begin
		Delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where IDArea=@AreaId)
		update ccInbound set cam_id=null where inbound_id in (select inbound_id from ccInbound where IDArea=@AreaId)
		return(0)
	 end

	Delete ccCalifCamp where cam_id in (select cam_id from ccCamps where IDArea=@AreaId)
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
 end
set nocount off