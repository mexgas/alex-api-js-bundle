CREATE PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int = null,
@Descripcion varchar(40) = null,
@Cam_id varchar(1000),
@Activa tinyint = null,
@IDArea smallint = null,
@frame tinyint = null, 
@MirrorInbound_Id smallint = null,
@Prefijo varchar(40) = null
as
set nocount on

if @option = 0
	begin
		select cam_id,ISNULL(cam_descripcion,'''') as cam_descripcion,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'') as AreaName
		from ccCamps as CAMP with(nolock) 
		left join ccRIACat_Areas as AREas with(nolock) on CAMP.IDArea = AREas.IDArea
		return(0)
	end

if @option = 1 -- select Camp
	begin
		select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0) as Area_Id,
		prefijo as Prefijo
		from ccCamps a1 with(nolock) 
		inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
		return(0)
	end

if @option = 4 --Delete
	begin
		if exists (select inbound_id from ccInbound with(nolock) where cam_id = @Cam_id)
		begin
		declare @error varchar(70)
		Select @error=case valor when 0 then 'No es posible eliminar la campaña, esta asociada a una especialidad'
			else 'Campaign can not be deleted, it has an association with an ACD' end
		from ccsettings with(nolock) where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
		end

		delete ccCampsHorarios with(rowlock) where cam_id = @Cam_id
		insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id) Values(@Cam_id, 5, 0, 0, @UserId)
		Delete ccCalifCamp with(rowlock) where cam_id = @Cam_id and tipo = 1
		Delete ccRIACampsGraph with(rowlock) where cam_id = @Cam_id
		delete ccHistorialListaNegra with(rowlock) where cam_id = @Cam_id
		delete ccRIARegistryLists with(rowlock) where cam_id = @Cam_id	
		return(0)
	end

if @option = 2 --Insert
	begin
	declare @new_cam_id smallint
	declare @isAssingPortbyCam bit


	if exists(select cam_descripcion from ccCamps with(nolock) where cam_descripcion = @Descripcion)
		begin
		select -1 --, 'Nombre en Uso'
		return(0)  
		end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1
	declare @pref int
	select  @pref = valor from ccSettings where setting_id = 201
	if (@pref = 0)
		set @Prefijo = ''


	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd,prefijo)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end,@Prefijo

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
		begin
		select -2 --, 'Error al crear campaña'
		return(0)
		end

	if isnull(@MirrorInbound_Id, 0)<>0
		begin
		if not exists(select inbound_id from ccInbound with(nolock) where inbound_id=@MirrorInbound_Id)
			begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
			end

		update ccinbound with(rowlock) set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps with(rowlock) set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
		end
	set @isAssingPortbyCam=1

	select @isAssingPortbyCam=valor from ccSettings where setting_id=232

	if @isAssingPortbyCam=1 begin
		insert into ccoDialerCamp (dialer_id, cam_id) 
		select dialer_id, @new_cam_id from ccoDialers with(nolock) where status = 1
	end

	insert into ccCalifCamp (calif_id, cam_id, tipo) 
	select calif_id, @new_cam_id, 1 from ccTipoCalifOUT with(nolock) where CalifOut_Status = 1

	update ccCamps set keepDial=dbo.fn_keepDial_Camps(@new_cam_id) where cam_id=@new_cam_id

	If not exists (select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
		end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock)  where frame = @frame and type_id = 1

	--inserta la lista negra por default
	if (select valor from ccsettings with(nolock) where setting_id=152)='1'
	begin
		declare @tempId as int
		DECLARE @dnclId TABLE 
		(
			id int 
		);
		insert into @dnclId
		exec dbo.ccsp_RIACATBList null, null, 5
		select @tempId=id from @dnclId;
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end

	select @new_cam_id
	return(0)
	end

if @option = 3 -- Update
	begin
		if not exists(select frame from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		insert into ccRIAGraphics (frame,type_id) values (@frame,1)

		Update ccCamps with(rowlock) set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

		update ccRIACampsGraph with(rowlock)
		set graphic_id = (select graphic_id from ccRIAGraphics with(index(IX_ccRIAGraphics_I),nolock) where frame = @frame and type_id = 1)
		where cam_id = @Cam_id

		return(0)
	end

	if @option = 5 --Obtener relaciones de campañas - campañas
	begin
		if not exists (select cam_id from ccCamps with(nolock) where cam_id = @Cam_id) or
		(@descripcion is not null and @descripcion <> '' and @descripcion <> '0' and 
		not exists (select cam_id from ccCamps with(nolock) where cam_id=@descripcion))
		begin
		select -3 -- Campaña invalida
		return(0)
		end
				
	if @descripcion=0
		set @descripcion = null

	update ccCamps with(rowlock) set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
					
	else
		begin
		delete cccalifcamp with(rowlock) where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

		end

	return(0)
	end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

if @option = 7 -- Checa si la campaña no tiene grabaciones y se puede modificar el prefijo
	begin	
		select count(*) as Grabaciones from ccoCallsOut where cam_id = @Cam_id
		--select 0 as Grabaciones	
	end

if @option = 8 -- Checa si la campaña tiene asignada una campaña tipo encuesta
	begin	
		SELECT CAST(CASE WHEN  isnull(surveycamid,0) != 0 THEN 1 ELSE 0 END AS bit)
		from cccamps with(index(PK_ccCamps),nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off